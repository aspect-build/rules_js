// Dumps the state a js_binary launcher leaves node in, so that the bash launcher
// (js/private/js_binary.sh.tpl) and the JavaScript one (js/private/js_binary.cjs.tpl) can be
// compared directly.
//
// This runs after js/private/node-bootstrap/bootstrap.cjs, which is deliberate: bootstrap.cjs
// is common to both launchers, so what it does is the same on both sides, and what this prints
// is what a js_binary program actually observes.

import * as fs from 'node:fs'
import * as path from 'node:path'

// Dropped before comparison. Everything not listed here has to match.
const DROPPED = new Set([
    // Bash bookkeeping. These are artifacts of the shell rather than launcher output.
    '_',
    'OLDPWD',
    'SHLVL',
    // Set per action by Bazel, not by either launcher.
    'TMPDIR',
    // Exported by the hermetic_launcher stub for legacy runfiles consumers.
    'JAVA_RUNFILES',
    // This fixture's own plumbing; it names the output file, which differs per variant.
    'JS_LAUNCHER_SYNC_OUT',
])

// Each variant runs as its own action and gets its own sandbox, and the launcher under test is
// built in its own configuration. Neither difference is launcher behavior, so both are
// replaced with tokens.
//
// The execroot is derived from the cwd rather than read from JS_BINARY__EXECROOT, so that
// JS_BINARY__EXECROOT itself stays genuinely compared.
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
// symlink even when both launchers are correct.
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
