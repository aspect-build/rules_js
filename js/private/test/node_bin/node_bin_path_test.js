// The launcher puts each wrapper's directory on the PATH so that child processes resolve `node`
// (and, with include_npm, `npm`) to the wrapper rather than to whatever else is around. That only
// works if a directory holds a single PATH-resolvable spelling of the command: a POSIX shell
// resolves the extensionless file, while cmd.exe resolves .bat / .cmd / .exe via PATHEXT. If both
// are present, which one a child gets depends on the shell it happens to use, and it need not be
// the wrapper the launcher selected.
//
// Under runfiles only the selected wrapper is a runfile, so this holds trivially. Under
// JS_BINARY__NO_RUNFILES the directory on the PATH is the source directory in the execroot, which
// holds every file in the package -- that is the case this guards.
const fs = require('fs')
const path = require('path')

function checkWrapperDir(command, wrapper) {
    const dir = path.dirname(wrapper)
    const re = new RegExp(`^${command}\\.(bat|cmd|exe)$`, 'i')
    const candidates = fs.readdirSync(dir).filter((e) => e === command || re.test(e))

    console.log(`${command} wrapper:    ${wrapper}`)
    console.log(`${command} PATH dir:   ${dir}`)
    console.log(`${command} candidates: ${JSON.stringify(candidates)}`)

    if (candidates.length !== 1) {
        throw new Error(
            `Expected exactly one PATH-resolvable '${command}' in ${dir}, found ` +
                `${candidates.length}: ${candidates.join(', ')}. A child process may resolve one ` +
                `of these instead of the wrapper the launcher selected ` +
                `(${path.basename(wrapper)}).`
        )
    }

    if (candidates[0] !== path.basename(wrapper)) {
        throw new Error(
            `PATH lookup for '${command}' in ${dir} resolves ${candidates[0]}, but the launcher ` +
                `selected ${path.basename(wrapper)}`
        )
    }
}

const nodeWrapper = process.env.JS_BINARY__NODE_WRAPPER
if (!nodeWrapper) {
    throw new Error('JS_BINARY__NODE_WRAPPER is not set')
}
checkWrapperDir('node', nodeWrapper)

// The npm wrapper is only on the PATH when include_npm is set, and it is not exported, so locate
// it among the PATH entries the launcher added. Both wrapper directories sit directly under
// js/private, so anchor on the node wrapper's parent: scanning the whole PATH would pick up a
// system npm and check that instead.
const wrapperRoot = path.dirname(path.dirname(nodeWrapper))
const npmWrapper = (process.env.PATH || '')
    .split(path.delimiter)
    .filter((dir) => dir.startsWith(wrapperRoot + path.sep) || dir.startsWith(wrapperRoot + '/'))
    .flatMap((dir) => ['npm', 'npm.bat', 'npm.cmd'].map((f) => path.join(dir, f)))
    .find((p) => fs.existsSync(p))

if (npmWrapper) {
    checkWrapperDir('npm', npmWrapper)
} else {
    console.log('npm not on the PATH (include_npm is not set); skipping npm check')
}
