// An absolute BAZEL_BINDIR inherited from the shell under `bazel run` does not resolve from
// the runfiles tree the launcher starts in, so the launcher must leave the runfiles tree alone
// and still find the execroot from it.
import { execFileSync } from 'node:child_process'
import * as fs from 'node:fs'
import { runfiles } from '@bazel/runfiles'

const launcher = runfiles.resolve(process.argv[2])
// A runfiles tree, which is where `bazel run` starts a binary.
const runfilesDir = process.cwd()
// Any absolute directory that exists will do; it stands in for the workspace directory.
const bindir = fs.realpathSync(process.env.TEST_TMPDIR)

const env = {
    ...process.env,
    BAZEL_BINDIR: bindir,
    BUILD_WORKSPACE_DIRECTORY: bindir,
}

let stdout = ''
try {
    stdout = execFileSync(launcher, [], {
        cwd: runfilesDir,
        encoding: 'utf8',
        env,
        stdio: ['ignore', 'pipe', 'inherit'],
    })
} catch (e) {
    process.stderr.write(`probe failed with exit code ${e.status}:\n${e.stdout || ''}\n`)
    process.exit(1)
}

const failures = []
if (!/^execroot ok: /m.test(stdout)) {
    failures.push('probe did not report execroot ok')
}
const cwd = /^cwd: (.*)$/m.exec(stdout)?.[1]
if (cwd !== runfilesDir) {
    failures.push(`probe cwd '${cwd}' is not the runfiles directory '${runfilesDir}'`)
}
if (failures.length) {
    for (const failure of failures) {
        console.error(`FAIL: ${failure}`)
    }
    console.error(stdout)
    process.exit(1)
}

console.log('an absolute BAZEL_BINDIR left the runfiles tree alone')
