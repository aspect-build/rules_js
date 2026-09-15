// A launch with no BAZEL_BINDIR cannot change into the root of the output tree if it is
// not already there, so the launcher preload has to reject it.
import { execFileSync } from 'node:child_process'
import { runfiles } from '@bazel/runfiles'

const launcher = runfiles.resolve(process.argv[2])

const env = { ...process.env }
delete env.BAZEL_BINDIR

let status = 0
let stderr = ''
try {
    // Not the test's temporary directory: that is inside the output tree, which is one of the cases
    // the preload accepts. The root directory always exists and is not part of the output tree.
    execFileSync(launcher, [], {
        cwd: '/',
        encoding: 'utf8',
        env,
        stdio: ['ignore', 'pipe', 'pipe'],
    })
} catch (e) {
    status = e.status
    stderr = e.stderr || ''
}

// The log prefix names the rule, which is js_test here because the package is testonly, so
// match from the level and the message rather than spelling the whole line out.
const expected =
    /^FATAL: .*: BAZEL_BINDIR must be set in environment to the makevar/m
if (status !== 1 || !expected.test(stderr)) {
    process.stderr.write(
        `expected exit code 1 and ${expected}, got exit code ${status} and:\n${stderr}\n`
    )
    process.exit(1)
}

console.log('a launch with no BAZEL_BINDIR was rejected')
