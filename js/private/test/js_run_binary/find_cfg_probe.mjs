// The purpose of this binary is to determine where the generated file
// cfg_probe.txt ended up. We look for it in both the exec and target bin
// directories and output the path where it appears.
import fs from 'fs'
import path from 'path'

const suffix = 'js/private/test/js_run_binary/cfg_probe.txt'
const execCfgRelPath = path.join(process.env.JS_BINARY__BINDIR, suffix)
const targetCfgRelPath = path.join(process.env.BAZEL_BINDIR, suffix)

function fileExists(absPath) {
    try {
        fs.lstatSync(absPath)
        return true
    } catch (_) {
        return false
    }
}

const foundInExecCfg = fileExists(path.join(process.env.JS_BINARY__EXECROOT, execCfgRelPath))
const foundInTargetCfg = fileExists(path.join(process.env.JS_BINARY__EXECROOT, targetCfgRelPath))

if (foundInExecCfg && foundInTargetCfg) {
    process.stderr.write('cfg_probe.txt unexpectedly found in both exec cfg and target cfg paths\n')
    process.exit(1)
}
if (!foundInExecCfg && !foundInTargetCfg) {
    process.stderr.write('cfg_probe.txt not found in either exec cfg or target cfg path\n')
    process.exit(1)
}

process.stdout.write((foundInExecCfg ? execCfgRelPath : targetCfgRelPath) + '\n')
