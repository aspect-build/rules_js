// Tests for the AspectWatchProtocol client message framing and error routing,
// driven against scripted fake servers on a real unix socket.
import * as net from 'node:net'
import * as os from 'node:os'
import * as path from 'node:path'
import * as assert from 'node:assert'
import { AspectWatchProtocol } from '../../watch/aspect_watch_protocol.mjs'

let socketCounter = 0
function socketPath() {
    return path.join(
        os.tmpdir(),
        `watch-proto-test-${process.pid}-${socketCounter++}.sock`
    )
}

// Line-framed JSON fake server; `onMessage` scripts its side of the protocol.
function serveScript(onMessage, onConnect) {
    const file = socketPath()
    const srv = net.createServer((conn) => {
        let tail = ''
        if (onConnect) onConnect(conn)
        conn.on('data', (data) => {
            tail += data.toString()
            let nl
            while ((nl = tail.indexOf('\n')) !== -1) {
                const line = tail.slice(0, nl).trim()
                tail = tail.slice(nl + 1)
                if (line) onMessage(conn, JSON.parse(line))
            }
        })
    })
    return new Promise((resolve) =>
        srv.listen(file, () => resolve({ file, srv }))
    )
}

function negotiate(conn) {
    conn.write(JSON.stringify({ kind: 'NEGOTIATE', versions: [1] }) + '\n')
}

function handshakeHandler(conn, msg, { coalesceFirstCycle = false } = {}) {
    if (msg.kind === 'NEGOTIATE_RESPONSE') {
        assert.equal(msg.version, 1)
        return true
    }
    if (msg.kind === 'CAPS') {
        const capsResp =
            JSON.stringify({
                kind: 'CAPS_RESPONSE',
                caps: { scope: ['runfiles'] },
            }) + '\n'
        if (coalesceFirstCycle) {
            // CAPS_RESPONSE and the first CYCLE coalesced into ONE write/chunk.
            conn.write(
                capsResp +
                    JSON.stringify({
                        kind: 'CYCLE',
                        cycle_id: 1,
                        sources: { 'a.txt': null },
                    }) +
                    '\n'
            )
        } else {
            conn.write(capsResp)
        }
        return true
    }
    return false
}

async function test(name, fn) {
    await fn()
    console.log(`PASS: ${name}`)
}

// Multiple messages coalesced into a single 'data' chunk must be framed apart.
await test('coalesced messages in one chunk', async () => {
    const cycles = []
    const { file, srv } = await serveScript((conn, msg) => {
        if (handshakeHandler(conn, msg, { coalesceFirstCycle: true })) return
        if (msg.kind === 'CYCLE_COMPLETED') {
            assert.equal(msg.cycle_id, 1)
            conn.end()
        }
    }, negotiate)

    const w = new AspectWatchProtocol(file)
    w.onError((e) => {
        throw e
    })
    w.onCycle(async (msg) => cycles.push(msg))
    await w.connect()
    await w.awaitFirstCycle()
    assert.equal(cycles.length, 1)
    assert.deepEqual(cycles[0].sources, { 'a.txt': null })
    await w.disconnect()
    srv.close()
})

// A message split across many chunks, including mid-JSON boundaries.
await test('message split across chunks', async () => {
    const cycles = []
    const { file, srv } = await serveScript((conn, msg) => {
        if (handshakeHandler(conn, msg)) {
            if (msg.kind === 'CAPS') {
                // Dribble a CYCLE out in 5 byte chunks after the handshake.
                const cycle =
                    JSON.stringify({
                        kind: 'CYCLE',
                        cycle_id: 1,
                        sources: {},
                    }) + '\n'
                let i = 0
                const step = () => {
                    if (i < cycle.length) {
                        conn.write(cycle.slice(i, i + 5))
                        i += 5
                        setTimeout(step, 1)
                    }
                }
                step()
            }
            return
        }
        if (msg.kind === 'CYCLE_COMPLETED') conn.end()
    }, negotiate)

    const w = new AspectWatchProtocol(file)
    w.onCycle(async (msg) => cycles.push(msg))
    await w.connect()
    await w.awaitFirstCycle()
    assert.equal(cycles.length, 1)
    await w.disconnect()
    srv.close()
})

// A message arriving while the client has no receive pending must be queued.
await test('message arriving between receives is queued, not dropped', async () => {
    const cycles = []
    const { file, srv } = await serveScript((conn, msg) => {
        if (handshakeHandler(conn, msg)) {
            if (msg.kind === 'CAPS') {
                conn.write(
                    JSON.stringify({
                        kind: 'CYCLE',
                        cycle_id: 1,
                        sources: {},
                    }) + '\n'
                )
            }
            return
        }
        if (msg.kind === 'CYCLE_COMPLETED') conn.end()
    }, negotiate)

    const w = new AspectWatchProtocol(file)
    w.onCycle(async (msg) => cycles.push(msg))
    await w.connect()
    // Idle: the CYCLE arrives now, with no _receive() outstanding.
    await new Promise((r) => setTimeout(r, 100))
    await w.awaitFirstCycle()
    assert.equal(cycles.length, 1)
    await w.disconnect()
    srv.close()
})

// An out-of-order message during the handshake: catchable error, not a crash.
await test('early CYCLE during handshake rejects connect()', async () => {
    const { file, srv } = await serveScript((conn, msg) => {
        if (msg.kind === 'CAPS') {
            // Protocol violation: CYCLE instead of CAPS_RESPONSE.
            conn.write(
                JSON.stringify({ kind: 'CYCLE', cycle_id: 1, sources: {} }) +
                    '\n'
            )
        }
    }, negotiate)

    const w = new AspectWatchProtocol(file)
    await assert.rejects(
        () => w.connect(),
        /Expected message kind CAPS_RESPONSE, got CYCLE/
    )
    await w.disconnect()
    srv.close()
})

// The server closing mid-cycle-loop surfaces as a catchable error.
await test('server close during cycle loop rejects catchably', async () => {
    const { file, srv } = await serveScript((conn, msg) => {
        if (handshakeHandler(conn, msg)) {
            if (msg.kind === 'CAPS') setTimeout(() => conn.destroy(), 20)
            return
        }
    }, negotiate)

    const w = new AspectWatchProtocol(file)
    w.onCycle(async () => {})
    await w.connect()
    await assert.rejects(() => w.cycle(), /connection closed/)
    srv.close()
})

console.log('All watch protocol tests passed.')
