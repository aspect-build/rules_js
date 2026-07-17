// Test that an EXIT message from the watch protocol server ends the
// AspectWatchProtocol cycle loop cleanly instead of throwing.
import * as net from 'node:net'
import * as os from 'node:os'
import * as path from 'node:path'
import * as assert from 'node:assert'
import { AspectWatchProtocol } from '../../watch/aspect_watch_protocol.mjs'

const socketFile = path.join(
    os.tmpdir(),
    `watch-proto-test-${process.pid}-exit.sock`
)

// A minimal scripted server: handshake, then an immediate EXIT.
const srv = net.createServer((conn) => {
    let tail = ''
    conn.write(JSON.stringify({ kind: 'NEGOTIATE', versions: [1] }) + '\n')
    conn.on('data', (data) => {
        tail += data.toString()
        let nl
        while ((nl = tail.indexOf('\n')) !== -1) {
            const line = tail.slice(0, nl).trim()
            tail = tail.slice(nl + 1)
            if (!line) continue

            const msg = JSON.parse(line)
            if (msg.kind === 'NEGOTIATE_RESPONSE') {
                assert.equal(msg.version, 1)
            } else if (msg.kind === 'CAPS') {
                conn.write(
                    JSON.stringify({
                        kind: 'CAPS_RESPONSE',
                        caps: { scope: ['runfiles'] },
                    }) + '\n'
                )
                // Delayed so the client is inside cycle() awaiting the message.
                setTimeout(
                    () =>
                        conn.write(
                            JSON.stringify({
                                kind: 'EXIT',
                                description: 'shutting down',
                            }) + '\n'
                        ),
                    50
                )
            }
        }
    })
})
await new Promise((resolve) => srv.listen(socketFile, resolve))

const w = new AspectWatchProtocol(socketFile)
w.onCycle(async () => {
    throw new Error('no cycle expected')
})
await w.connect()
await w.cycle() // resolves (does not throw) on EXIT
await w.disconnect()
srv.close()

console.log('PASS: EXIT ends cycle() cleanly')
