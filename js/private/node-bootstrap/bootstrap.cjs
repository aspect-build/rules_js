const path = require('path')
const patchfs = require('./fs.cjs').patcher
const {
    JS_BINARY__EXECROOT,
    JS_BINARY__FS_PATCH_ROOTS,
    JS_BINARY__LOG_DEBUG,
    JS_BINARY__LOG_PREFIX,
    JS_BINARY__NODE_WRAPPER,
    JS_BINARY__PATCH_NODE_FS,
    JS_BINARY__RUNFILES,
} = process.env

// Keep a count of how many times these patches are applied; this should reflect the depth
// of child processes in the default case where a child process inherits process.env since
// child processes need to re-apply the patches. This is here primarily for testing but it
// could also be useful for debugging.
if (!process.env.JS_BINARY__NODE_PATCHES_DEPTH) {
    process.env.JS_BINARY__NODE_PATCHES_DEPTH = '.'
} else {
    process.env.JS_BINARY__NODE_PATCHES_DEPTH += '.'
}

// subprocess patch
if (process.platform == 'win32') {
    // FIXME: need to make an exe, or run in a shell so we can use .bat
} else {
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: overriding process.execPath to node wrapper path ${JS_BINARY__NODE_WRAPPER}`
        )
    }
    process.argv[0] = process.execPath = JS_BINARY__NODE_WRAPPER
}

// Put the node wrapper directory first on the PATH so that child processes resolve `node` to it.
if (JS_BINARY__NODE_WRAPPER) {
    const wrapperDir = path.dirname(JS_BINARY__NODE_WRAPPER)
    const entries = (process.env.PATH || '')
        .split(path.delimiter)
        .filter(Boolean)

    // Child processes re-run this bootstrap, so don't keep re-prepending the same directory.
    if (entries[0] !== wrapperDir) {
        process.env.PATH = [wrapperDir, ...entries].join(path.delimiter)
    }
    if (JS_BINARY__LOG_DEBUG) {
        console.error(`DEBUG: ${JS_BINARY__LOG_PREFIX}: PATH ${process.env.PATH}`)
    }
}

// Configure the fs patch roots, and export the environment variable so that
// they are visible to any other js_binary that this process might invoke.
if (!JS_BINARY__FS_PATCH_ROOTS && JS_BINARY__EXECROOT && JS_BINARY__RUNFILES) {
    process.env.JS_BINARY__FS_PATCH_ROOTS =
        `${JS_BINARY__EXECROOT}:${JS_BINARY__RUNFILES}`
}

// fs patches
if (
    JS_BINARY__PATCH_NODE_FS &&
    JS_BINARY__PATCH_NODE_FS != '0' &&
    process.env.JS_BINARY__FS_PATCH_ROOTS
) {
    const roots = process.env.JS_BINARY__FS_PATCH_ROOTS.split(':')
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: node fs patches will be applied with roots: ${roots}`
        )
    }
    patchfs(roots)
}
