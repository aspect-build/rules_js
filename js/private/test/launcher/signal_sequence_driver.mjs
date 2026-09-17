// Spawns the target js_binary and sends it SIGINT once it reports READY, then SIGTERM once it
// reports GOT_INT, so the second signal only goes out after the launcher has forwarded the
// first. A launcher that stops trapping every signal after the first one is terminated by the
// SIGTERM instead, and the target never prints HANDLED.
//
// The launcher must then still wait for the target's exit code, which its expected_exit_code
// remaps to 0.
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
    if (!out.includes('HANDLED')) {
        process.stderr.write(
            `SIGTERM was not forwarded after SIGINT (exit code=${code} signal=${sig}); ` +
                `target output was ${JSON.stringify(out)}\n`
        )
        process.exit(1)
    }
    if (code !== 0) {
        process.stderr.write(
            `the launcher did not wait for the target's exit code ` +
                `(exit code=${code} signal=${sig})\n`
        )
        process.exit(1)
    }
    process.exit(0)
})
