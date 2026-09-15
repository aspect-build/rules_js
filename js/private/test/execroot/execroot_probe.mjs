// Checks JS_BINARY__EXECROOT, which the launcher preload works out from the directory the
// launcher script was started in, undoing the change into BAZEL_BINDIR that the script makes
// before starting node.
import * as fs from 'node:fs'
import * as path from 'node:path'

const execroot = process.env.JS_BINARY__EXECROOT
const bindir = process.env.BAZEL_BINDIR
const cwd = process.cwd()
const failures = []

if (!execroot) {
    failures.push('JS_BINARY__EXECROOT is not set')
} else {
    if (!path.isAbsolute(execroot)) {
        failures.push(
            `JS_BINARY__EXECROOT '${execroot}' is not an absolute path`
        )
    }
    if (!fs.existsSync(execroot)) {
        failures.push(`JS_BINARY__EXECROOT '${execroot}' does not exist`)
    }
    // Cutting one segment too few or too many off the current directory still names a
    // directory, so check that this one is the root of the output tree.
    if (!fs.existsSync(path.join(execroot, 'bazel-out'))) {
        failures.push(
            `JS_BINARY__EXECROOT '${execroot}' has no bazel-out directory`
        )
    }
    if (cwd !== execroot && !cwd.startsWith(execroot + path.sep)) {
        failures.push(
            `cwd '${cwd}' is not under JS_BINARY__EXECROOT '${execroot}'`
        )
    }
    // Where there is a bindir to change into, the execroot is what it was changed from.
    if (
        bindir &&
        !process.env.JS_BINARY__NO_CD_BINDIR &&
        cwd !== path.resolve(execroot, bindir)
    ) {
        failures.push(
            `cwd '${cwd}' is not BAZEL_BINDIR '${bindir}' under JS_BINARY__EXECROOT '${execroot}'`
        )
    }
}

if (failures.length) {
    for (const failure of failures) {
        console.error(`FAIL: ${failure}`)
    }
    process.exit(1)
}

console.log(`execroot ok: ${execroot}`)
