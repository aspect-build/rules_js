// Entry point for the differential test: the same js_binary is run as a
// js_run_binary tool twice, once through the bash launcher and once through the
// hermetic launcher, and the two reports this writes must be byte-identical.
//
// Everything recorded here is therefore normalized against the runfiles root or the
// execroot, since those differ between the two targets. Anything that cannot be
// normalized away is a difference in launcher behaviour, which is the point.

const fs = require('fs')
const path = require('path')
const { spawnSync } = require('child_process')

const execroot = process.env.JS_BINARY__EXECROOT
const runfiles = process.env.JS_BINARY__RUNFILES
const bindir = process.env.BAZEL_BINDIR

// The one argument is the report path, relative to the bindir. Writing it relative to
// the current directory is the assertion that the launcher left us in the bindir: if
// it did not, Bazel reports the declared output as missing.
//
// Which launcher ran goes in a file of its own rather than in the report, since the
// whole point of the report is that it does not depend on the launcher. Its path is
// derived rather than passed, so that argv itself stays free of anything that differs
// between the two targets.
const out = process.argv[2]
const launcherOut = out.replace('report_', 'launcher_').replace('.json', '.txt')

function fromRunfiles(p) {
    return p ? path.relative(runfiles, p) : null
}

// Which tree a path is in, rather than where it is on this machine. The two launchers
// reach the same file through differently-named roots, and in execroot mode the entry
// point is not in the runfiles tree at all -- it is the bindir copy.
function normalize(p) {
    if (!p) {
        return null
    }
    const bindirRoot = path.join(execroot, bindir)
    for (const [name, root] of [
        ['<runfiles>', runfiles],
        ['<bindir>', bindirRoot],
        ['<execroot>', execroot],
    ]) {
        if (p === root || p.startsWith(root + path.sep)) {
            return path.posix.join(name, path.relative(root, p))
        }
    }
    return p
}

// Proves the node wrapper is on the PATH and works, which is what keeps a child
// process that shells out to `node` on the patched runtime.
function childExecPath() {
    const child = spawnSync('node', ['-p', 'process.execPath'], { encoding: 'utf8' })
    return child.status === 0 ? fromRunfiles(child.stdout.trim()) : `failed: ${child.status}`
}

const report = {
    // The "everything runs from the root of the output tree" contract.
    cwd_is_bindir: process.cwd() === path.join(execroot, bindir),

    // --bazel-bindir is for the launcher, not the program.
    argv_after_out: process.argv.slice(3),
    argv_has_bazel_bindir: process.argv.includes('--bazel-bindir'),

    // In execroot mode this is the bindir copy, which is the whole of what that mode
    // means: node resolves the program's own requires by walking up from here, so
    // module_search_root below is the assertion that actually matters.
    entry_point: normalize(process.argv[1]),
    main_is_this_module: require.main === module,
    main_filename: normalize(require.main && require.main.filename),
    module_search_root: normalize(module.paths[0]),
    exec_path: fromRunfiles(process.execPath),
    path_first_entry: fromRunfiles((process.env.PATH || '').split(path.delimiter)[0]),
    child_exec_path: childExecPath(),
    node_wrapper: fromRunfiles(process.env.JS_BINARY__NODE_WRAPPER),

    // Recorded as an invariant rather than a path, because the two launchers legitimately
    // differ here and the path would drown out anything that does not:
    //
    // - JS_BINARY__NODE_BINARY is a runfiles path under the bash launcher, but the
    //   hermetic one takes it from process.execPath, which node reports as a realpath.
    // - JS_BINARY__NODE_PATCHES is bootstrap.cjs under the bash launcher and launcher.cjs
    //   under the hermetic one, which is the whole point of the preload.
    node_binary_exists: fs.existsSync(process.env.JS_BINARY__NODE_BINARY || ''),
    node_patches_exists: fs.existsSync(process.env.JS_BINARY__NODE_PATCHES || ''),

    fs_patched: Boolean(fs._unpatched),
    // The second root is the runfiles tree, whose directory is named after the tool
    // target, and the hermetic run's tool is the wrapper.
    patch_roots: (process.env.JS_BINARY__FS_PATCH_ROOTS || '')
        .split(':')
        .map((root) => (root === runfiles ? '<runfiles>' : path.relative(execroot, root))),
    node_patches_depth: process.env.JS_BINARY__NODE_PATCHES_DEPTH,

    preserve_symlinks_main: process.execArgv.includes('--preserve-symlinks-main'),
    compile_cache_disabled: process.env.NODE_DISABLE_COMPILE_CACHE,
}

fs.mkdirSync(path.dirname(out), { recursive: true })
fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n')

// bootstrap.cjs is preloaded directly by the bash launcher; launcher.cjs only by the
// hermetic one. Without this the differential test could compare a launcher to itself
// and pass for the wrong reason.
fs.writeFileSync(launcherOut, path.basename(process.env.JS_BINARY__NODE_PATCHES) + '\n')
