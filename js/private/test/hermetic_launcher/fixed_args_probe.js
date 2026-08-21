// Entry point for the fixed_args differential test. The js_binary under test has
// `fixed_args` in the documented form -- a literal flag plus
// "$$RUNFILES_DIR/$(rlocationpath ...)" -- which the bash launcher produces by shell
// expansion and the hermetic launcher by resolving an embedded argument through its
// runfiles. The two reports this writes must be byte-identical.

const fs = require('fs')
const path = require('path')

const runfiles = process.env.JS_BINARY__RUNFILES

// The fixed args come first, exactly as the launcher script orders them, so the report
// path that js_run_binary passes is last.
const args = process.argv.slice(2)
const out = args[args.length - 1]

// Normalized against the runfiles root, which differs between the two targets: the
// hermetic run's tool is the wrapper, and a runfiles tree is named after its target.
const dataPath = args[args.indexOf('--data') + 1]

const report = {
    // The whole point: an embedded argument the launcher resolved, and the shell
    // expansion it has to match.
    data_arg_absolute: path.isAbsolute(dataPath),
    data_arg: path.relative(runfiles, dataPath),
    data_readable: JSON.parse(fs.readFileSync(dataPath, 'utf8')),

    // A fixed arg with nothing to expand has to survive verbatim, and in position.
    args_before_out: args
        .slice(0, -1)
        .map((arg) => (arg === dataPath ? '<data>' : arg)),
}

fs.mkdirSync(path.dirname(out), { recursive: true })
fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n')

// Same guard as the main differential test: proves the two sides really ran through
// different launchers rather than comparing one launcher with itself.
fs.writeFileSync(
    out.replace('report_', 'launcher_').replace('.json', '.txt'),
    path.basename(process.env.JS_BINARY__NODE_PATCHES) + '\n'
)
