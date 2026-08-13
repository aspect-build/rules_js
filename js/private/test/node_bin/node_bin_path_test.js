// The launcher puts the directory containing JS_BINARY__NODE_WRAPPER on the PATH so that child
// processes resolve `node` to the fs-patched wrapper. That only works if the directory holds a
// single PATH-resolvable `node`: a POSIX shell resolves the extensionless file, while cmd.exe
// resolves node.bat / node.cmd / node.exe via PATHEXT. If both are present, which one a child
// gets depends on the shell it happens to use, and it need not be the wrapper the launcher chose.
const fs = require('fs')
const path = require('path')

const wrapper = process.env.JS_BINARY__NODE_WRAPPER
if (!wrapper) {
    throw new Error('JS_BINARY__NODE_WRAPPER is not set')
}

const dir = path.dirname(wrapper)
const candidates = fs
    .readdirSync(dir)
    .filter((e) => e === 'node' || /^node\.(bat|cmd|exe)$/i.test(e))

console.log(`node wrapper:    ${wrapper}`)
console.log(`PATH directory:  ${dir}`)
console.log(`node candidates: ${JSON.stringify(candidates)}`)

if (candidates.length !== 1) {
    throw new Error(
        `Expected exactly one PATH-resolvable 'node' in ${dir}, found ${candidates.length}: ` +
            `${candidates.join(', ')}. A child process may resolve one of these instead of the ` +
            `wrapper the launcher selected (${path.basename(wrapper)}).`
    )
}

if (candidates[0] !== path.basename(wrapper)) {
    throw new Error(
        `PATH lookup for 'node' in ${dir} resolves ${candidates[0]}, but the launcher selected ` +
            `${path.basename(wrapper)}`
    )
}
