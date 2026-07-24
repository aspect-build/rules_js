// Spawns the target js_binary, waits for it to report READY, then sends the
// signal named by argv[3] (default SIGTERM) to the launcher process itself (a
// directed signal to a single PID, mirroring e.g. `docker stop` to PID 1 rather
// than a terminal Ctrl-C sent to the whole process group). The launcher must
// forward that signal to node, so the test passes only if node's own signal
// handler prints HANDLED.
import { spawn } from 'node:child_process'
import { runfiles } from '@bazel/runfiles'

const targetRlocation = process.argv[2]
const signal = process.argv[3] || 'SIGTERM'
if (!targetRlocation) {
    process.stderr.write(
        'Usage: signal_driver.mjs <target-rlocationpath> [signal]\n'
    )
    process.exit(1)
}

const target = runfiles.resolve(targetRlocation)
const child = spawn(target, [], { stdio: ['ignore', 'pipe', 'inherit'] })

let out = ''
let signalled = false

const timeout = setTimeout(() => {
    process.stderr.write(`timed out waiting for child to handle ${signal}\n`)
    child.kill('SIGKILL')
    process.exit(1)
}, 10000)

child.stdout.on('data', (chunk) => {
    out += chunk.toString()
    if (!signalled && out.includes('READY')) {
        signalled = true
        child.kill(signal)
    }
})

// Wait for 'close' rather than 'exit' so all buffered stdout has been
// delivered to the data listener before asserting on HANDLED.
child.on('close', (code, sig) => {
    clearTimeout(timeout)
    if (out.includes('HANDLED')) {
        process.exit(0)
    }
    process.stderr.write(
        `${signal} was not forwarded to node (exit code=${code} signal=${sig}); ` +
            `child output was ${JSON.stringify(out)}\n`
    )
    process.exit(1)
})
