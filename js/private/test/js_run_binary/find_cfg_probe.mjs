// The purpose of this binary is to determine where the generated file
// cfg_probe.txt ended up. We always expect it to appear in the runfiles, but
// depending on the situation it may also appear in the target bin directory.
// If it is only in the runfiles, we output "RUNFILES_ONLY"; otherwise, we
// output the path in the target bin directory.
import fs from 'fs'
import path from 'path'
import { runfiles } from '@bazel/runfiles'

const rlocationPath = process.argv[2]
if (!rlocationPath) {
    process.stderr.write('Usage: find_cfg_probe.mjs <rlocation-path>\n')
    process.exit(1)
}

try {
    runfiles.resolve(rlocationPath)
} catch (_) {
    process.stderr.write(`cfg_probe.txt not found in runfiles at ${rlocationPath}\n`)
    process.exit(1)
}

// Strip the workspace name prefix to get the package-relative path under bin
const packageRelPath = rlocationPath.split('/').slice(1).join('/')
const targetBinRelPath = path.join(process.env.BAZEL_BINDIR, packageRelPath)
const targetBinAbsPath = path.join(process.env.JS_BINARY__EXECROOT, targetBinRelPath)

const foundInTargetBin = fs.existsSync(targetBinAbsPath)

process.stdout.write((foundInTargetBin ? targetBinRelPath : 'RUNFILES_ONLY') + '\n')
