// Runs as a user `node_options = ["--require", ...]` preload of preload_probe_bin. By the
// time node loads a user preload, the bash launcher must have changed into the bindir and
// launcher.cjs and bootstrap.cjs must both have run.
//
// Each line is a separate assert_contains in BUILD.bazel, so one failure names the
// invariant it broke.
const path = require('node:path')
const { execFileSync } = require('node:child_process')

// The child spawned below inherits this process's execArgv, and with it this very
// preload. Without this guard every child would spawn another, without end.
if (process.env.PRELOAD_PROBE_CHILD) {
    return
}

const cwd = process.cwd()
const bindir = process.env.BAZEL_BINDIR
console.log(
    `preload cwd is bindir: ${!!bindir && cwd.endsWith(path.sep + bindir.replace(/\//g, path.sep))}`
)
console.log(
    `preload sees node wrapper: ${!!process.env.JS_BINARY__NODE_WRAPPER}`
)
console.log(
    `preload sees node patches: ${!!process.env.JS_BINARY__NODE_PATCHES}`
)
console.log(
    `preload runs after bootstrap: ${process.env.JS_BINARY__NODE_PATCHES_DEPTH === '.'}`
)
console.log(
    `preload execArgv[1] is bootstrap: ${path.basename(process.execArgv[1] || '') === 'bootstrap.cjs'}`
)
console.log(
    `preload execArgv has no launcher: ${!process.execArgv.some((a) => a.endsWith('launcher.cjs'))}`
)

// A child that inherits execArgv the way child_process.fork does must get the
// per-process bootstrap once and the launcher not at all.
const child = execFileSync(
    process.execPath,
    [
        ...process.execArgv,
        '-e',
        'console.log(JSON.stringify([process.env.JS_BINARY__NODE_PATCHES_DEPTH, process.execArgv]))',
    ],
    { encoding: 'utf8', env: { ...process.env, PRELOAD_PROBE_CHILD: '1' } }
)
const [depth, childExecArgv] = JSON.parse(child)
console.log(`child depth is two: ${depth === '..'}`)
console.log(
    `child execArgv has no launcher: ${!childExecArgv.some((a) => a.endsWith('launcher.cjs'))}`
)
