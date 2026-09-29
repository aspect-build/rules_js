// Run by test.sh with `bazel run`, which starts a binary in its runfiles tree with the
// caller's environment. Checks what the launcher left the program with.
import * as fs from 'node:fs'
import * as path from 'node:path'

const execroot = process.env.JS_BINARY__EXECROOT
const cwd = process.cwd()
const failures = []

if (!execroot || !fs.existsSync(path.join(execroot, 'bazel-out'))) {
    failures.push(`JS_BINARY__EXECROOT '${execroot}' is not the root of the output tree`)
}
if (!cwd.endsWith(`${path.sep}bazel_run_env.runfiles${path.sep}_main`)) {
    failures.push(`cwd '${cwd}' is not the runfiles tree`)
}

if (failures.length) {
    for (const failure of failures) {
        console.error(`FAIL: ${failure}`)
    }
    process.exit(1)
}
console.log('bazel run env ok')
