// Dumps the state a js_binary launcher leaves node in, so that the bash launcher
// (js/private/js_binary.sh.tpl) and the JavaScript one (js/private/js_binary.cjs.tpl) can be
// compared directly.
//
// This runs after js/private/node-bootstrap/bootstrap.cjs, which is deliberate: bootstrap is
// common to both launchers, so what it does is the same on both sides, and what this prints is
// what a js_binary program actually observes.

import * as fs from 'node:fs'
import * as path from 'node:path'

// Dropped before comparison. Everything not listed here has to match, so keep this list short
// and say why for each entry.
const DROPPED = new Set([
    // Bash bookkeeping. The bash launcher is a bash process and the hermetic one is a native
    // stub that execve()s node, so these are artifacts of the shell rather than launcher output.
    '_', // bash exports the path of the command it is about to run
    'OLDPWD', // set by the `cd "$BAZEL_BINDIR"` in js_binary.sh.tpl
    'SHLVL', // incremented by every bash in the chain
    // Set per action by Bazel, not by either launcher.
    'TMPDIR',
    // Exported by the hermetic_launcher stub for legacy runfiles consumers before it hands off
    // to the launcher. RUNFILES_DIR, which both launchers do set, stays compared.
    'JAVA_RUNFILES',
    // This fixture's own plumbing; it names the output file, which differs per variant.
    'JS_LAUNCHER_SYNC_OUT',
])

// Each variant runs as its own action and so gets its own sandbox, and the launcher under test
// is built in its own configuration. Neither difference is launcher behavior, so both are
// replaced with tokens.
//
// The execroot is derived from the cwd rather than read from JS_BINARY__EXECROOT so that the
// value of JS_BINARY__EXECROOT stays genuinely compared: a launcher that computed it wrongly
// would leave an unsubstituted absolute path behind and fail the diff, rather than having its
// own mistake normalized away.
const cwd = process.cwd().replace(/\\/g, '/')
const bazelOut = cwd.lastIndexOf('/bazel-out/')
const execroot = bazelOut < 0 ? cwd : cwd.slice(0, bazelOut)

function normalize(value) {
    return (
        String(value)
            .replace(/\\/g, '/')
            .split(execroot)
            .join('<EXECROOT>')
            .replace(/bazel-out\/[^/]+\//g, 'bazel-out/<CFG>/')
    )
}

const lines = []
const emit = (key, value) =>
    lines.push(`${key}=${JSON.stringify(normalize(value))}`)

emit('cwd', cwd)
process.argv.forEach((arg, i) => emit(`argv[${i}]`, arg))
// Where node_options and the --require of node-patches land.
process.execArgv.forEach((arg, i) => emit(`execArgv[${i}]`, arg))

// Compared as a derived fact rather than by value: bash keeps a logical path across `cd` while
// process.cwd() is physical, so the two spellings can differ if any execroot component is a
// symlink even when both launchers are correct. What has to agree is that PWD is set and
// describes where we actually are.
lines.push(`pwd_is_cwd=${process.env.PWD === process.cwd()}`)

for (const key of Object.keys(process.env).sort()) {
    if (DROPPED.has(key) || key === 'PWD') continue
    emit(`env[${key}]`, process.env[key])
}

// Resolved against the execroot because the launcher has left us in the bindir.
fs.writeFileSync(
    path.join(execroot, process.env.JS_LAUNCHER_SYNC_OUT),
    lines.join('\n') + '\n'
)
