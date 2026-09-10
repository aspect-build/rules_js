// If the user opted into the compile cache, we explicitly enable it here. Node
// automatically enables it at startup if NODE_COMPILE_CACHE is set, but we cannot
// necessarily rely on that since the hermetic launcher does not set user-specified
// environment variables until after node has started. If the user did not opt in, we set
// NODE_DISABLE_COMPILE_CACHE so that any future calls to module.enableCompileCache() do
// not have an effect (aspect-build/rules_js#2937).
if (!process.env.NODE_DISABLE_COMPILE_CACHE) {
    if (process.env.NODE_COMPILE_CACHE) {
        require('node:module').enableCompileCache?.(
            process.env.NODE_COMPILE_CACHE
        )
    } else {
        process.env.NODE_DISABLE_COMPILE_CACHE = 1
    }
}

// Code coverage. We load this early on so that the coverage session sees as much of this
// process compiled under it as possible. We require coverage.cjs conditionally to cut
// down on code size for non-test targets.
if (process.env.JS_BINARY__COVERAGE_REPORT || process.env.COVERAGE_DIR) {
    require('./coverage.cjs')
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
    // chdir is relative to the root of the output tree, where an external repository's package sits
    // under "external/<repo>". The runfiles tree instead gives every repository a top-level
    // directory beside our own, so re-point the path there rather than leaving the tree. Bazel sets
    // TEST_SRCDIR for a test and BUILD_WORKSPACE_DIRECTORY for `bazel run`, and these are the two
    // situations where we will be in the runfiles tree.
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
