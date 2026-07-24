// Spawns the target js_binary, waits for it to report READY, sends the signal
// named by argv[3], and asserts node is terminated by that signal. On the exec
// path the launcher has replaced itself with node, so an unhandled fatal signal
// kills node directly and it is reported as signal-terminated (code=null),
// rather than the launcher surfacing a 128+N exit code.
import { spawn } from 'node:child_process'
import { runfiles } from '@bazel/runfiles'

const targetRlocation = process.argv[2]
const signal = process.argv[3]
if (!targetRlocation || !signal) {
    process.stderr.write(
        'Usage: signal_exit_driver.mjs <target-rlocationpath> <signal>\n'
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
    if (code === null && sig === signal) {
        process.exit(0)
    }
    process.stderr.write(
        `expected node to be terminated by ${signal}, but exited with code=${code} signal=${sig}\n`
    )
    process.exit(1)
})
