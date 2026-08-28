// The launcher exports NODE_DISABLE_COMPILE_CACHE unconditionally, and then we re-enable
// the cache here if necessary.
if (process.env.NODE_COMPILE_CACHE) {
    delete process.env.NODE_DISABLE_COMPILE_CACHE
    require('node:module').enableCompileCache?.(process.env.NODE_COMPILE_CACHE)
}

const patchfs = require('./fs.cjs').patcher
const {
    BUILD_WORKSPACE_DIRECTORY,
    JS_BINARY__CHDIR,
    JS_BINARY__FS_PATCH_ROOTS,
    JS_BINARY__LOG_DEBUG,
    JS_BINARY__LOG_PREFIX,
    JS_BINARY__NODE_WRAPPER,
    JS_BINARY__PATCH_NODE_FS,
    TEST_SRCDIR,
} = process.env

// Change directory as indicated by the chdir option on js_binary or js_run_binary.
if (JS_BINARY__CHDIR) {
    let dir = JS_BINARY__CHDIR
    // chdir is relative to the root of the output tree, where an external repository's package
    // sits under "external/<repo>". The runfiles tree instead gives every repository a top-level
    // directory beside our own, so re-point the path there rather than leaving the tree. Bazel
    // sets TEST_SRCDIR for a test and BUILD_WORKSPACE_DIRECTORY for `bazel run`; a build action,
    // which the launcher leaves at the root of the output tree, gets neither. See #2827.
    if ((TEST_SRCDIR || BUILD_WORKSPACE_DIRECTORY) && dir.startsWith('external/')) {
        dir = '../' + dir.slice('external/'.length)
    }
    try {
        process.chdir(dir)
    } catch (e) {
        console.error(
            `FATAL: ${JS_BINARY__LOG_PREFIX}: could not change directory to '${dir}': ${e.message}`
        )
        process.exit(1)
    }
    // process.chdir() does not maintain PWD, so let's update it here.
    process.env.PWD = process.cwd()
    // Prevent child processes and worker threads from attempting to cd a second time.
    delete process.env.JS_BINARY__CHDIR
}

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

// fs patches
if (
    JS_BINARY__PATCH_NODE_FS &&
    JS_BINARY__PATCH_NODE_FS != '0' &&
    JS_BINARY__FS_PATCH_ROOTS
) {
    const roots = JS_BINARY__FS_PATCH_ROOTS.split(':')
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: node fs patches will be applied with roots: ${roots}`
        )
    }
    patchfs(roots)
}

if (process.env.JS_BINARY__COVERAGE_REPORT) {
    require('./coverage.cjs')
}
