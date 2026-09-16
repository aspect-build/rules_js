// Spawns the target js_binary and sends it two different directed signals in
// turn: SIGINT once it reports READY, then SIGTERM once it reports GOT_INT, so
// the second signal is only sent after the launcher has finished forwarding the
// first. A launcher that stops trapping every signal after the first one leaves
// the SIGTERM to terminate it instead, and the target never prints HANDLED.
import { spawn } from 'node:child_process'
import { runfiles } from '@bazel/runfiles'

const targetRlocation = process.argv[2]
if (!targetRlocation) {
    process.stderr.write('Usage: signal_sequence_driver.mjs <target-rlocationpath>\n')
    process.exit(1)
}

const target = runfiles.resolve(targetRlocation)
const child = spawn(target, [], { stdio: ['ignore', 'pipe', 'inherit'] })

let out = ''
let sentInt = false
let sentTerm = false

const timeout = setTimeout(() => {
    process.stderr.write(
        `timed out waiting for the target to handle SIGTERM; output was ${JSON.stringify(out)}\n`
    )
    child.kill('SIGKILL')
    process.exit(1)
}, 10000)

child.stdout.on('data', (chunk) => {
    out += chunk.toString()
    if (!sentInt && out.includes('READY')) {
        sentInt = true
        child.kill('SIGINT')
    }
    if (!sentTerm && out.includes('GOT_INT')) {
        sentTerm = true
        child.kill('SIGTERM')
    }
})

// Wait for 'close' rather than 'exit' so all buffered stdout has been delivered
// to the data listener before asserting on HANDLED.
child.on('close', (code, sig) => {
    clearTimeout(timeout)
    if (out.includes('HANDLED')) {
        process.exit(0)
    }
    process.stderr.write(
        `SIGTERM was not forwarded after SIGINT (exit code=${code} signal=${sig}); ` +
            `target output was ${JSON.stringify(out)}\n`
    )
    process.exit(1)
})
