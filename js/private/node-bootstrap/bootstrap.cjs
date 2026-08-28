// The launcher exports NODE_DISABLE_COMPILE_CACHE unconditionally, and then we re-enable
// the cache here if necessary.
if (process.env.NODE_COMPILE_CACHE) {
    delete process.env.NODE_DISABLE_COMPILE_CACHE
    require('node:module').enableCompileCache?.(process.env.NODE_COMPILE_CACHE)
}

const patchfs = require('./fs.cjs').patcher
const {
    BAZEL_BINDIR,
    JS_BINARY__BINDIR,
    JS_BINARY__CHDIR,
    JS_BINARY__EXECROOT,
    JS_BINARY__FS_PATCH_ROOTS,
    JS_BINARY__LOG_DEBUG,
    JS_BINARY__LOG_PREFIX,
    JS_BINARY__NODE_WRAPPER,
    JS_BINARY__PATCH_NODE_FS,
} = process.env

// working directory
//
// js_binary(chdir) / js_run_binary(chdir). The launcher leaves us in the root of the output
// tree (or in the runfiles tree for a js_test) and hands the requested directory over in
// JS_BINARY__CHDIR; the move itself happens here so that it does not depend on the launcher
// being a shell script.
//
// Nothing in this process may observe the old cwd, so this runs before the fs patches and
// before coverage.cjs, which snapshots process.cwd() for the reporter it later spawns.
if (JS_BINARY__CHDIR) {
    // An "external/<repo>" chdir names a path in the bin directory rather than one relative to
    // the cwd we were given, which for a js_test is the runfiles tree. See #2827.
    const dir = JS_BINARY__CHDIR.startsWith('external/')
        ? require('node:path').join(
              JS_BINARY__EXECROOT,
              BAZEL_BINDIR || JS_BINARY__BINDIR,
              JS_BINARY__CHDIR
          )
        : JS_BINARY__CHDIR
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: changing directory to user specified package ${dir}`
        )
    }
    try {
        process.chdir(dir)
    } catch (e) {
        console.error(
            `FATAL: ${JS_BINARY__LOG_PREFIX}: could not change directory to '${dir}': ${e.message}`
        )
        process.exit(1)
    }
    // process.chdir() does not maintain PWD, which bash cd did and which some tools read.
    process.env.PWD = process.cwd()
    // The variable is an instruction to this process, and it has now been carried out, so
    // consume it. A child node process re-enters this bootstrap through the node wrapper's
    // --require, and a worker thread gets a copy of this environment; both already start in
    // the directory we just moved to, and applying a relative chdir on top of it would
    // compound (in a worker, process.chdir() throws outright).
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
