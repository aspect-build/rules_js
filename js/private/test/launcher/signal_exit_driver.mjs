// Spawns the target js_binary, waits for it to report READY, sends the signal
// named by argv[3], and asserts the launcher exits with the code in argv[4].
// When node is terminated by a signal it does not handle, the launcher must
// surface that as exit code 128+N (e.g. 143 for SIGTERM, 130 for SIGINT).
import { spawn } from 'node:child_process'
import { runfiles } from '@bazel/runfiles'

const targetRlocation = process.argv[2]
const signal = process.argv[3]
const expectedCode = Number(process.argv[4])
if (!targetRlocation || !signal || Number.isNaN(expectedCode)) {
    process.stderr.write(
        'Usage: signal_exit_driver.mjs <target-rlocationpath> <signal> <expected-exit-code>\n'
    )
    process.exit(1)
}

const target = runfiles.resolve(targetRlocation)
const child = spawn(target, [], { stdio: ['ignore', 'pipe', 'inherit'] })

let out = ''
let signalled = false

const timeout = setTimeout(() => {
    process.stderr.write(
        `timed out waiting for launcher to exit after ${signal}\n`
    )
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

child.on('exit', (code, sig) => {
    clearTimeout(timeout)
    if (code === expectedCode) {
        process.exit(0)
    }
    process.stderr.write(
        `launcher exited with code=${code} signal=${sig}, expected exit code ${expectedCode}\n`
    )
    process.exit(1)
})
