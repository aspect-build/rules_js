const path = require('path')
const { isMainThread } = require('worker_threads')
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

// Change directory to user specified package if set. This must happen before the entry_point
// module loads (guaranteed since this script runs via --require) but its own path resolution
// is unaffected since it was already resolved to an absolute path by the launcher. Only do this
// on the main thread: cwd is process-wide (already inherited by any worker thread once the main
// thread has changed it), and process.chdir() throws if called from within a worker thread.
if (JS_BINARY__CHDIR && isMainThread) {
    // Mirrors resolve_execroot_bin_path in js_binary.sh.tpl for the "external/*" case; for a
    // plain package-relative value, cwd is already BAZEL_BINDIR (or the runfiles root, when
    // running from within a test sandbox) by the time this launcher's bash script exec'd node,
    // so a relative chdir matches what the bash launcher used to do directly.
    const target = JS_BINARY__CHDIR.startsWith('external/')
        ? path.join(
              JS_BINARY__EXECROOT,
              BAZEL_BINDIR || JS_BINARY__BINDIR,
              JS_BINARY__CHDIR
          )
        : JS_BINARY__CHDIR
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: changing directory to user specified package ${JS_BINARY__CHDIR}`
        )
    }
    process.chdir(target)
    // Clear this so a process that inherits NODE_OPTIONS from this one (for example a worker
    // pool that forks using process.execPath, which we override below to the node wrapper) won't
    // see it set and try to re-apply it — by then cwd is already the target directory, and a
    // relative chdir against that would incorrectly try to go one level deeper. js_run_devserver
    // is the one other consumer of this variable; it infers the same value by comparing its own
    // (already chdir'd) cwd against RUNFILES_ROOT / BAZEL_BINDIR instead of reading this env var.
    delete process.env.JS_BINARY__CHDIR
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

// Put the node wrapper directory on the PATH so that child processes find it first,
// making the wrapper available as `node` on the PATH at runtime.
if (JS_BINARY__NODE_WRAPPER) {
    process.env.PATH = [path.dirname(JS_BINARY__NODE_WRAPPER), process.env.PATH]
        .filter(Boolean)
        .join(path.delimiter)
    if (JS_BINARY__LOG_DEBUG) {
        console.error(`DEBUG: ${JS_BINARY__LOG_PREFIX}: PATH ${process.env.PATH}`)
    }
}

// fs patches
if (JS_BINARY__PATCH_NODE_FS && JS_BINARY__PATCH_NODE_FS != '0') {
    // Configure fs patch roots for node fs patches which are run via --require in the node
    // wrapper. Don't override an already-set JS_BINARY__FS_PATCH_ROOTS in case a js_binary
    // such as js_run_deverser runs another js_binary tool.
    const fsPatchRoots =
        JS_BINARY__FS_PATCH_ROOTS ||
        (JS_BINARY__EXECROOT && JS_BINARY__RUNFILES
            ? `${JS_BINARY__EXECROOT}:${JS_BINARY__RUNFILES}`
            : undefined)

    if (fsPatchRoots) {
        const roots = fsPatchRoots.split(':')
        if (JS_BINARY__LOG_DEBUG) {
            console.error(
                `DEBUG: ${JS_BINARY__LOG_PREFIX}: node fs patches will be applied with roots: ${roots}`
            )
        }
        patchfs(roots)
    }
}
