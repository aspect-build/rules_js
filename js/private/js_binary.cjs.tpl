// This JavaScript file is the launcher for the NodeJS JavaScript file
// entry point with the following bazel label:
//     {{entry_point_label}}
//
// The launcher was generated to execute the js_binary target
//     {{target_label}}
//
// The template used to generate this launcher is
//     {{template_label}}

'use strict'

const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { spawn } = require('node:child_process')

// ==============================================================================
// Helpers
// ==============================================================================

const IS_WINDOWS = process.platform === 'win32'

// Normalizes paths when running on Windows.
//
// Example:
// C:\Users\XUser\_bazel_XUser\7q7kkv32\execroot\A\b\C -> C:/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C
//
// Only the separator changes. The bash launcher this replaced also rewrote the
// drive letter (C:\... -> /c/...) because that is the only form MSYS bash, which
// ran it, understands. Node is not MSYS: it reads /c/... as \c\... on the current
// drive, so every path built from one would miss. Node does accept forward
// slashes on Windows, so the separator rewrite is all that is needed and the
// comparisons below can stay written with '/'.
function normalizePath(p) {
    if (!IS_WINDOWS) {
        return p
    }
    return p.replace(/\\/g, '/')
}

// process.cwd() reports the native separator on Windows, so it has to be
// normalized everywhere it is compared against or spliced into a path built with
// '/'. Not hoisted into a constant: the launcher chdir()s further down.
function cwd() {
    return normalizePath(process.cwd())
}

// The env values, node options and fixed args below were spliced into
// double-quoted bash strings before this launcher was ported to JavaScript, so
// shell parameter expansion happened at launch time and users depend on it. For
// example examples/stack_traces passes
// node_options = ["--require", "$$JS_BINARY__RUNFILES/$$JS_BINARY__WORKSPACE/..."].
// Only $VAR / ${VAR} expansion is reproduced here; command substitution is not,
// and the result is not re-split on whitespace the way bash would have.
function expandEnvRefs(value) {
    return value.replace(
        /\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))/g,
        (_match, braced, bare) => process.env[braced || bare] || ''
    )
}

function setEnv(name, value) {
    process.env[name] = expandEnvRefs(value)
}

// Matches bash `if [[ -z "${name:-}" ]]`, which is true when unset *or* empty.
function setEnvIfUnset(name, value) {
    if (!process.env[name]) {
        process.env[name] = expandEnvRefs(value)
    }
}

function isFile(p) {
    try {
        return fs.statSync(p).isFile()
    } catch {
        return false
    }
}

function isDirectory(p) {
    try {
        return fs.statSync(p).isDirectory()
    } catch {
        return false
    }
}

function isExecutable(p) {
    try {
        fs.accessSync(p, fs.constants.X_OK)
        return true
    } catch {
        return false
    }
}

// ==============================================================================
// Environment
// ==============================================================================

{{envs}}

// ==============================================================================
// Handle --bazel-bindir flag
// ==============================================================================

// If a --bazel-bindir <path> flag is passed it must be the first two
// arguments. It is consumed by this launcher and used to set BAZEL_BINDIR,
// overriding any value already set in the environment.
const argv = process.argv.slice(2)
if (argv.length > 0 && argv[0] === '--bazel-bindir') {
    if (argv.length < 2) {
        fs.writeSync(2, 'ERROR: --bazel-bindir flag requires a value\n')
        process.exit(1)
    }
    process.env.BAZEL_BINDIR = argv[1]
    argv.splice(0, 2)
}

// ==============================================================================
// Prepare logging
// ==============================================================================

// Unlike the bash launcher this one implements neither stdout, stderr nor exit
// code capture, and neither silent_on_success. All four need work after the
// program has exited, and js_run_binary already delegates all four to
// run_binary's spawn wrapper -- a process that outlives the program and can do
// that work (aspect-build/rules_js#2955). So JS_BINARY__STDOUT_OUTPUT_FILE,
// JS_BINARY__STDERR_OUTPUT_FILE, JS_BINARY__EXIT_CODE_OUTPUT_FILE and
// JS_BINARY__SILENT_ON_SUCCESS are ignored here rather than honoured; see
// docs/hermetic_launcher.md.
//
// expected_exit_code is the one thing in that family that is implemented, since
// it is a js_binary attribute with no other home. It costs the exec fast path
// below.

process.env.JS_BINARY__LOG_PREFIX = '{{log_prefix_rule_set}}[{{log_prefix_rule}}]'

// Emit a log line to stderr.
//
// The bash launcher formatted these with `echo -e $(printf ...)`, whose unquoted
// command substitution collapsed every run of whitespace in the message to a
// single space. The multi-line diagnostics below rely on that to render on one
// line, so the collapsing is reproduced here.
//
// fs.writeSync rather than console.error, so that the line is flushed before the
// execve() at the bottom replaces this process.
function logTo(level, message) {
    const collapsed = message.trim().replace(/\s+/g, ' ')
    fs.writeSync(2, `${level}: ${process.env.JS_BINARY__LOG_PREFIX}: ${collapsed}\n`)
}

function logfFatal(message) {
    if (process.env.JS_BINARY__LOG_FATAL) {
        logTo('FATAL', message)
    }
}

function logfError(message) {
    if (process.env.JS_BINARY__LOG_ERROR) {
        logTo('ERROR', message)
    }
}

function logfInfo(message) {
    if (process.env.JS_BINARY__LOG_INFO) {
        logTo('INFO', message)
    }
}

function logfDebug(message) {
    if (process.env.JS_BINARY__LOG_DEBUG) {
        logTo('DEBUG', message)
    }
}

function resolveExecrootBinPath(shortPath) {
    const bindir = process.env.BAZEL_BINDIR
    if (shortPath.startsWith('../')) {
        return `${process.env.JS_BINARY__EXECROOT}/${bindir}/external/${shortPath.slice(3)}`
    }
    return `${process.env.JS_BINARY__EXECROOT}/${bindir}/${shortPath}`
}

function resolveExecrootSrcPath(shortPath) {
    if (shortPath.startsWith('../')) {
        return `${process.env.JS_BINARY__EXECROOT}/external/${shortPath.slice(3)}`
    }
    return `${process.env.JS_BINARY__EXECROOT}/${shortPath}`
}

// The tail of the bash launcher's `_exit` trap, which is all that is left of it
// now that there are no captured streams to replay and no temp files to remove.
function exitWith(exitCode) {
    logfDebug(`exit code: ${exitCode}`)
    process.exit(exitCode)
}

// The bash launcher this replaced ran under `set -o errexit` with `trap _exit
// EXIT`, so a failure anywhere below still logged the exit code on its way out.
// Nothing in JavaScript does that by default: an uncaught throw --
// process.chdir() on a directory that does not exist, say -- would print a raw
// stack trace instead of this launcher's own diagnostics.
//
// Whatever comes to run the entry point in this process rather than exec'ing has
// to remove this handler first, or it will report the program's own uncaught
// exceptions as launcher failures.
process.on('uncaughtException', (err) => {
    // The message alone: logTo collapses whitespace, so a stack trace comes out
    // as one unreadable line. It is still worth having when debugging the
    // launcher.
    logfFatal(String((err && err.message) || err))
    logfDebug(String((err && err.stack) || err))
    exitWith(1)
})

// Ends this process the way node ended, so that callers see a signal-terminated
// process rather than an interposed 128+N exit code. That is what they would
// have seen had this launcher been able to exec node instead of spawning it.
function reraiseSignal(signal, exitCode) {
    logfDebug(`exit code: ${exitCode}`)
    // Removing the last listener restores node's default disposition for the
    // signal, so killing ourselves with it now terminates this process.
    process.removeAllListeners('SIGTERM')
    process.removeAllListeners('SIGINT')
    process.kill(process.pid, signal)
    // Only reached if the signal turned out not to be fatal after all.
    process.exit(exitCode)
}

// ==============================================================================
// Initialize RUNFILES environment variable
// ==============================================================================

// Port of the runfiles resolution the bash launcher used to do, minus the cases
// that cannot arise here: the native launcher that exec'd this file had to find
// node and this launcher in the runfiles to get here at all, and it exports the
// one source it settled on -- RUNFILES_DIR when it picked a materialized tree,
// RUNFILES_MANIFEST_FILE otherwise. So there is no $0 walk to do.
let runfiles = process.env.TEST_SRCDIR || process.env.RUNFILES_DIR
if (!runfiles && process.env.RUNFILES_MANIFEST_FILE) {
    // Normalized before the suffix tests because on Windows Bazel hands out a
    // backslash-separated path, which would not match '/MANIFEST'.
    const manifest = normalizePath(process.env.RUNFILES_MANIFEST_FILE)
    if (manifest.endsWith('.runfiles_manifest')) {
        // Bazel puts the manifest besides the runfiles with the suffix
        // .runfiles_manifest. For example, the runfiles directory is named
        // my_binary.runfiles then the manifest is beside the runfiles directory
        // and named my_binary.runfiles_manifest
        runfiles = manifest.slice(0, -'_manifest'.length)
    } else if (manifest.endsWith('/MANIFEST')) {
        // Bazel for windows puts the manifest file named MANIFEST in the
        // runfiles directory
        runfiles = manifest.slice(0, -'/MANIFEST'.length)
    } else {
        logfFatal(`Unexpected RUNFILES_MANIFEST_FILE value ${manifest}`)
        exitWith(1)
    }
}
if (!runfiles) {
    logfFatal('RUNFILES_DIR environment variable is not set')
    exitWith(1)
}
runfiles = normalizePath(runfiles)
if (!path.isAbsolute(runfiles)) {
    // Must be absolute: the runfiles path may be relative to the cwd, and we may
    // be about to change directory.
    runfiles = normalizePath(path.join(cwd(), runfiles))
}
process.env.JS_BINARY__RUNFILES = runfiles
// Set RUNFILES_DIR if not already set so that tools such as @bazel/runfiles can
// locate runfiles.
process.env.RUNFILES_DIR = process.env.RUNFILES_DIR || runfiles

// ==============================================================================
// Prepare to run main program
// ==============================================================================

let bazelOutSegment
if (cwd().includes('/bazel-out/')) {
    bazelOutSegment = '/bazel-out/'
} else if (cwd().includes('/BAZEL-~1/')) {
    bazelOutSegment = '/BAZEL-~1/'
} else if (cwd().includes('/bazel-~1/')) {
    bazelOutSegment = '/bazel-~1/'
}

// When the cwd is a build action execroot the bindir hangs off it (BAZEL_BINDIR resolves from the
// cwd), so the cwd is the execroot even if its path contains a "bazel-out" segment (e.g. a matching
// output base). Otherwise scan the output tree for the execroot (runfiles, or a nested js_binary in
// the bindir).
if (
    bazelOutSegment &&
    (!process.env.BAZEL_BINDIR ||
        !isDirectory(path.join(cwd(), process.env.BAZEL_BINDIR)))
) {
    if (
        process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT &&
        process.env.JS_BINARY__EXECROOT
    ) {
        logfDebug(
            `inheriting JS_BINARY__EXECROOT ${process.env.JS_BINARY__EXECROOT} from parent js_binary process as JS_BINARY__USE_EXECROOT_ENTRY_POINT is set`
        )
    } else {
        // We are in runfiles and we don't yet know the execroot; strip from the last "bazel-out" segment
        const index = cwd().lastIndexOf(bazelOutSegment)
        if (index < 0) {
            fs.writeSync(
                2,
                `\nERROR: ${process.env.JS_BINARY__LOG_PREFIX}: No 'bazel-out' folder found in path '${cwd()}'\n`
            )
            exitWith(1)
        }
        process.env.JS_BINARY__EXECROOT = cwd().slice(0, index)
    }
} else {
    if (
        process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT &&
        process.env.JS_BINARY__EXECROOT
    ) {
        logfDebug(
            `inheriting JS_BINARY__EXECROOT ${process.env.JS_BINARY__EXECROOT} from parent js_binary process as JS_BINARY__USE_EXECROOT_ENTRY_POINT is set`
        )
    } else {
        // We are in execroot or in some other context all together such as a nodejs_image or a manually run js_binary
        process.env.JS_BINARY__EXECROOT = cwd()
    }

    if (!process.env.JS_BINARY__NO_CD_BINDIR) {
        if (!process.env.BAZEL_BINDIR) {
            logfFatal(
                `BAZEL_BINDIR must be set in environment to the makevar $(BINDIR) in js_binary build actions (which
run in the execroot) so that build actions can change directories to always run out of the root of the Bazel output
tree. See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_variables. This is automatically set
by 'js_run_binary' (https://github.com/aspect-build/rules_js/blob/main/docs/js_run_binary.md) which is the recommended
rule to use for using a js_binary as the tool of a build action. If you are invoking a js_binary directly from your own
custom rule implementation, use the 'js_binary_lib.run_binary_action' helper
(https://github.com/aspect-build/rules_js/blob/main/js/libs.bzl) instead of calling ctx.actions.run yourself so that
BAZEL_BINDIR is set correctly. If this is not a build action you can set the
BAZEL_BINDIR to '.' instead to supress this error. For more context on this design decision, please read the
aspect_rules_js README https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs.`
            )
            exitWith(1)
        }

        // Since the process was launched in the execroot, we automatically change directory into the root of the
        // output tree (which we expect to be set in BAZEL_BIN). See
        // https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
        // for more context on why we do this.
        logfDebug(
            `changing directory to BAZEL_BINDIR (root of Bazel output tree) ${process.env.BAZEL_BINDIR}`
        )
        process.chdir(process.env.BAZEL_BINDIR)
        // The bash launcher changed directory with `cd`, which maintains the exported PWD.
        // process.chdir() does not, so update it here -- the same fixup bootstrap.cjs does
        // after its own chdir. Programs and the child processes they spawn read PWD.
        process.env.PWD = process.cwd()
    }
}

if (process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT) {
    if (!process.env.BAZEL_BINDIR) {
        logfFatal(
            'Expected BAZEL_BINDIR to be set when JS_BINARY__USE_EXECROOT_ENTRY_POINT is set'
        )
        exitWith(1)
    }
    if (
        !process.env.JS_BINARY__COPY_DATA_TO_BIN &&
        !process.env.JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN
    ) {
        logfFatal(
            `Expected js_binary copy_data_to_bin to be True when js_run_binary use_execroot_entry_point is True.
To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary`
        )
        exitWith(1)
    }
}

if (process.env.JS_BINARY__NO_RUNFILES) {
    if (
        !process.env.JS_BINARY__COPY_DATA_TO_BIN &&
        !process.env.JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN
    ) {
        logfFatal(
            `Expected js_binary copy_data_to_bin to be True when js_binary use_execroot_entry_point is True.
To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary`
        )
        exitWith(1)
    }
}

let entryPoint
if (
    process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT ||
    process.env.JS_BINARY__NO_RUNFILES
) {
    entryPoint = resolveExecrootBinPath('{{entry_point_path}}')
} else {
    entryPoint = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{entry_point_path}}`
}
if (!isFile(entryPoint)) {
    logfFatal(`the entry_point '${entryPoint}' not found`)
    exitWith(1)
}

const node = normalizePath('{{node}}')
if (path.isAbsolute(node)) {
    // A user may specify an absolute path to node using target_tool_path in node_toolchain
    process.env.JS_BINARY__NODE_BINARY = node
} else if (process.env.JS_BINARY__NO_RUNFILES) {
    process.env.JS_BINARY__NODE_BINARY = resolveExecrootSrcPath('{{node}}')
} else {
    process.env.JS_BINARY__NODE_BINARY = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{node}}`
}
if (!isFile(process.env.JS_BINARY__NODE_BINARY)) {
    logfFatal(`node binary '${process.env.JS_BINARY__NODE_BINARY}' not found`)
    exitWith(1)
}
if (!IS_WINDOWS && !isExecutable(process.env.JS_BINARY__NODE_BINARY)) {
    logfFatal(`node binary '${process.env.JS_BINARY__NODE_BINARY}' is not executable`)
    exitWith(1)
}

let npmBinDir
const npm = '{{npm}}'
if (npm) {
    const npmPath = normalizePath(npm)
    if (path.isAbsolute(npmPath)) {
        // A user may specify an absolute path to npm using npm_path in node_toolchain
        process.env.JS_BINARY__NPM_BINARY = npmPath
    } else if (process.env.JS_BINARY__NO_RUNFILES) {
        process.env.JS_BINARY__NPM_BINARY = resolveExecrootSrcPath('{{npm}}')
    } else {
        process.env.JS_BINARY__NPM_BINARY = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{npm}}`
    }
    if (!isFile(process.env.JS_BINARY__NPM_BINARY)) {
        logfFatal(`npm binary '${process.env.JS_BINARY__NPM_BINARY}' not found`)
        exitWith(1)
    }
    if (!IS_WINDOWS && !isExecutable(process.env.JS_BINARY__NPM_BINARY)) {
        logfFatal(`npm binary '${process.env.JS_BINARY__NPM_BINARY}' is not executable`)
        exitWith(1)
    }

    let npmWrapper
    if (process.env.JS_BINARY__NO_RUNFILES) {
        npmWrapper = resolveExecrootSrcPath('{{npm_wrapper}}')
    } else {
        npmWrapper = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{npm_wrapper}}`
    }
    if (!isFile(npmWrapper)) {
        logfFatal(`npm wrapper '${npmWrapper}' not found`)
        exitWith(1)
    }
    if (!IS_WINDOWS && !isExecutable(npmWrapper)) {
        logfFatal(`npm wrapper '${npmWrapper}' is not executable`)
        exitWith(1)
    }
    npmBinDir = path.dirname(npmWrapper)
}

if (process.env.JS_BINARY__NO_RUNFILES) {
    process.env.JS_BINARY__NODE_WRAPPER = resolveExecrootSrcPath('{{node_wrapper}}')
} else {
    process.env.JS_BINARY__NODE_WRAPPER = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{node_wrapper}}`
}
if (!isFile(process.env.JS_BINARY__NODE_WRAPPER)) {
    logfFatal(`node wrapper '${process.env.JS_BINARY__NODE_WRAPPER}' not found`)
    exitWith(1)
}
if (!IS_WINDOWS && !isExecutable(process.env.JS_BINARY__NODE_WRAPPER)) {
    logfFatal(`node wrapper '${process.env.JS_BINARY__NODE_WRAPPER}' is not executable`)
    exitWith(1)
}

if (process.env.JS_BINARY__NO_RUNFILES) {
    process.env.JS_BINARY__NODE_PATCHES = resolveExecrootSrcPath('{{node_patches}}')
} else {
    process.env.JS_BINARY__NODE_PATCHES = `${process.env.JS_BINARY__RUNFILES}/{{workspace_name}}/{{node_patches}}`
}
if (!isFile(process.env.JS_BINARY__NODE_PATCHES)) {
    logfFatal(`node patches '${process.env.JS_BINARY__NODE_PATCHES}' not found`)
    exitWith(1)
}

// Gather node options
const nodeOptions = []
function addNodeOption(value) {
    nodeOptions.push(expandEnvRefs(value))
}
{{node_options}}

// fixed_args were tokenized at analysis time. Runtime $VAR expansion still
// happens here.
const FIXED_ARGS = {{fixed_args}}

const args = []
for (const arg of [...FIXED_ARGS.map(expandEnvRefs), ...argv]) {
    if (arg.startsWith('--node_options=')) {
        // Let users pass through arguments to node itself
        nodeOptions.push(arg.slice('--node_options='.length))
    } else {
        // Remaining argv is collected to pass to the program
        args.push(arg)
    }
}

// Configure JS_BINARY__FS_PATCH_ROOTS for node fs patches which are run via --require below.
// Don't override JS_BINARY__FS_PATCH_ROOTS if already set by an outer js_binary incase a js_binary such
// as js_run_deverser runs another js_binary tool.
if (!process.env.JS_BINARY__FS_PATCH_ROOTS) {
    process.env.JS_BINARY__FS_PATCH_ROOTS = `${process.env.JS_BINARY__EXECROOT}:${process.env.JS_BINARY__RUNFILES}`
}

// Disable Node's module compile cache by default (aspect-build/rules_js#2937).
// We will re-enable it at runtime if NODE_COMPILE_CACHE is set.
process.env.NODE_DISABLE_COMPILE_CACHE = '1'

// Put the node wrapper directory and optionally the npm wrapper directory on the path so that
// child processes can find them.
// `${undefined}` would interpolate the literal string "undefined" and put a bogus directory of
// that name on the path. Bash never hits this -- it always has a PATH of its own -- so an empty
// string is what the bash launcher's "$PATH" would have expanded to.
const currentPath = process.env.PATH || ''
if (npmBinDir) {
    process.env.PATH = `${npmBinDir}${path.delimiter}${currentPath}`
}
process.env.PATH = `${path.dirname(process.env.JS_BINARY__NODE_WRAPPER)}${path.delimiter}${process.env.PATH}`

// Debug logs
if (process.env.JS_BINARY__LOG_DEBUG) {
    logfDebug(`PATH ${process.env.PATH}`)
    if (process.env.BAZEL_BINDIR) {
        logfDebug(`BAZEL_BINDIR ${process.env.BAZEL_BINDIR}`)
    }
    if (process.env.BAZEL_BUILD_FILE_PATH) {
        logfDebug(`BAZEL_BUILD_FILE_PATH ${process.env.BAZEL_BUILD_FILE_PATH}`)
    }
    if (process.env.BAZEL_COMPILATION_MODE) {
        logfDebug(`BAZEL_COMPILATION_MODE ${process.env.BAZEL_COMPILATION_MODE}`)
    }
    if (process.env.BAZEL_INFO_FILE) {
        logfDebug(`BAZEL_INFO_FILE ${process.env.BAZEL_INFO_FILE}`)
    }
    if (process.env.BAZEL_PACKAGE) {
        logfDebug(`BAZEL_PACKAGE ${process.env.BAZEL_PACKAGE}`)
    }
    if (process.env.BAZEL_TARGET_CPU) {
        logfDebug(`BAZEL_TARGET_CPU ${process.env.BAZEL_TARGET_CPU}`)
    }
    if (process.env.BAZEL_TARGET_NAME) {
        logfDebug(`BAZEL_TARGET_NAME ${process.env.BAZEL_TARGET_NAME}`)
    }
    if (process.env.BAZEL_VERSION_FILE) {
        logfDebug(`BAZEL_VERSION_FILE ${process.env.BAZEL_VERSION_FILE}`)
    }
    if (process.env.BAZEL_WORKSPACE) {
        logfDebug(`BAZEL_WORKSPACE ${process.env.BAZEL_WORKSPACE}`)
    }
    logfDebug(`JS_BINARY__FS_PATCH_ROOTS ${process.env.JS_BINARY__FS_PATCH_ROOTS || ''}`)
    logfDebug(`JS_BINARY__NODE_PATCHES ${process.env.JS_BINARY__NODE_PATCHES || ''}`)
    logfDebug(`JS_BINARY__NODE_OPTIONS ${nodeOptions.join(' ')}`)
    logfDebug(`JS_BINARY__BINDIR ${process.env.JS_BINARY__BINDIR || ''}`)
    logfDebug(`JS_BINARY__BUILD_FILE_PATH ${process.env.JS_BINARY__BUILD_FILE_PATH || ''}`)
    logfDebug(`JS_BINARY__COMPILATION_MODE ${process.env.JS_BINARY__COMPILATION_MODE || ''}`)
    logfDebug(`JS_BINARY__NODE_BINARY ${process.env.JS_BINARY__NODE_BINARY || ''}`)
    logfDebug(`JS_BINARY__NODE_WRAPPER ${process.env.JS_BINARY__NODE_WRAPPER || ''}`)
    if (process.env.JS_BINARY__NPM_BINARY) {
        logfDebug(`JS_BINARY__NPM_BINARY ${process.env.JS_BINARY__NPM_BINARY}`)
    }
    if (process.env.JS_BINARY__NO_RUNFILES) {
        logfDebug(`JS_BINARY__NO_RUNFILES ${process.env.JS_BINARY__NO_RUNFILES}`)
    }
    logfDebug(`JS_BINARY__PACKAGE ${process.env.JS_BINARY__PACKAGE || ''}`)
    logfDebug(`JS_BINARY__TARGET_CPU ${process.env.JS_BINARY__TARGET_CPU || ''}`)
    logfDebug(`JS_BINARY__TARGET_NAME ${process.env.JS_BINARY__TARGET_NAME || ''}`)
    logfDebug(`JS_BINARY__WORKSPACE ${process.env.JS_BINARY__WORKSPACE || ''}`)
    logfDebug(`js_binary entry point ${entryPoint}`)
    if (process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT) {
        logfDebug(
            `JS_BINARY__USE_EXECROOT_ENTRY_POINT ${process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT}`
        )
    }
}

// Info logs
if (process.env.JS_BINARY__LOG_INFO) {
    if (process.env.BAZEL_TARGET) {
        logfInfo(`BAZEL_TARGET ${process.env.BAZEL_TARGET}`)
    }
    logfInfo(`JS_BINARY__TARGET ${process.env.JS_BINARY__TARGET || ''}`)
    logfInfo(`JS_BINARY__RUNFILES ${process.env.JS_BINARY__RUNFILES || ''}`)
    logfInfo(`JS_BINARY__EXECROOT ${process.env.JS_BINARY__EXECROOT || ''}`)
    logfInfo(`PWD ${cwd()}`)
}

// ==============================================================================
// Run the main program
// ==============================================================================

// We invoke node directly rather than through JS_BINARY__NODE_WRAPPER. This
// way we avoid spawning an extra bash process on every launch. The wrapper is
// still put on the PATH as `node` so that child processes get the patched
// runtime.

const nodeArgs = [
    '--require',
    process.env.JS_BINARY__NODE_PATCHES,
    ...nodeOptions,
    '--',
    entryPoint,
    ...args,
]

logfInfo(['running', process.env.JS_BINARY__NODE_BINARY, ...nodeArgs].join(' '))

const expectedExitCode = process.env.JS_BINARY__EXPECTED_EXIT_CODE

if (!expectedExitCode) {
    // Nothing must run after node exits, so replace this process with node.
    // Signals and terminal control are then delivered directly to node instead
    // of being proxied through a child process, and no launcher process is left
    // behind -- which is why this is the only path the bash launcher's `exec`
    // had, and why it is the one almost every js_binary takes.
    //
    // process.execve is POSIX-only and was added in Node 22.15; when it is
    // unavailable we fall through to spawning node below.
    if (typeof process.execve === 'function') {
        try {
            process.execve(
                process.env.JS_BINARY__NODE_BINARY,
                [process.env.JS_BINARY__NODE_BINARY, ...nodeArgs],
                { ...process.env }
            )
        } catch (e) {
            logfDebug(`process.execve failed (${e.message}); falling back to spawn`)
        }
    }
}

// Reached when this launcher has to outlive the program: an expected exit code
// has to be compared against once the program is done, and a Node before 22.15
// -- or any Node on Windows -- has no process.execve to replace this process
// with. This is the bash launcher's fork-and-wait path.
const child = spawn(process.env.JS_BINARY__NODE_BINARY, nodeArgs, {
    stdio: 'inherit',
})

// ==============================================================================
// Wait for program to finish
// ==============================================================================

// Node does not forward termination signals to any child process, so the
// signals are trapped and forwarded manually. The handlers are removed on the
// first signal so that a second one terminates this launcher.
function forwardSignal(signal) {
    return () => {
        process.removeAllListeners('SIGTERM')
        process.removeAllListeners('SIGINT')
        try {
            child.kill(signal)
        } catch {
            // the child already exited
        }
    }
}
process.on('SIGTERM', forwardSignal('SIGTERM'))
process.on('SIGINT', forwardSignal('SIGINT'))

child.on('error', (err) => {
    logfFatal(
        `failed to spawn node binary '${process.env.JS_BINARY__NODE_BINARY}': ${err.message}`
    )
    exitWith(127)
})

child.on('exit', (code, signal) => {
    const result =
        signal !== null && signal !== undefined
            ? 128 + (os.constants.signals[signal] || 0)
            : code

    // ==============================================================================
    // Mop up after main program
    // ==============================================================================

    if (expectedExitCode) {
        if (String(result) !== String(expectedExitCode)) {
            logfError(
                `expected exit code to be '${expectedExitCode}', but got '${result}'`
            )
            if (result === 0) {
                // This exit code is handled specially by Bazel:
                // https://github.com/bazelbuild/bazel/blob/486206012a664ecb20bdb196a681efc9a9825049/src/main/java/com/google/devtools/build/lib/util/ExitCode.java#L44
                const BAZEL_EXIT_TESTS_FAILED = 3
                exitWith(BAZEL_EXIT_TESTS_FAILED)
            }
            exitWith(result)
        } else {
            exitWith(0)
        }
    }

    if (signal) {
        reraiseSignal(signal, result)
    } else {
        exitWith(result)
    }
})
