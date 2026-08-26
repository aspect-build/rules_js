// This JavaScript file is the launcher for the NodeJS JavaScript file
// entry point with the following bazel label:
//     @@//js/private/test:snapshot.js
//
// The launcher was generated to execute the js_binary target
//     @@//js/private/test:snapshot_launcher
//
// The template used to generate this launcher is
//     @@//js/private:js_binary.cjs.tpl

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
// C:/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C -> /c/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C
function normalizePath(p) {
    if (!IS_WINDOWS) {
        return p
    }
    return p
        .replace(/^(.):/, (_match, drive) => '/' + drive.toLowerCase())
        .replace(/\\/g, '/')
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

setEnv("JS_BINARY__BINDIR", "bazel-out/k8-fastbuild/bin")
setEnv("JS_BINARY__COMPILATION_MODE", "fastbuild")
setEnv("JS_BINARY__TARGET_CPU", "k8")
setEnv("JS_BINARY__BUILD_FILE_PATH", "js/private/test/BUILD.bazel")
setEnv("JS_BINARY__PACKAGE", "js/private/test")
setEnv("JS_BINARY__TARGET_NAME", "snapshot_launcher")
setEnv("JS_BINARY__TARGET", "//js/private/test:snapshot_launcher")
setEnv("JS_BINARY__WORKSPACE", "_main")
setEnvIfUnset("JS_BINARY__PATCH_NODE_FS", "1")
setEnv("JS_BINARY__COPY_DATA_TO_BIN", "1")
setEnvIfUnset("JS_BINARY__LOG_FATAL", "1")
setEnvIfUnset("JS_BINARY__LOG_ERROR", "1")

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
// Prepare stdout capture, stderr capture && logging
// ==============================================================================

// Convert stdout, stderr and exit_code capture outputs paths to absolute paths.
// A path not starting with "bazel-out/" is relative to the bin directory; joining
// it with BAZEL_BINDIR here (rather than baking in bazel-out/<config>/bin at
// analysis time) keeps it correct when path mapping is active. This must happen
// before any directory changes below since it resolves against the cwd.
function resolveCapturePath(p) {
    if (p.startsWith('bazel-out/')) {
        return path.join(process.cwd(), p)
    }
    return path.join(
        process.cwd(),
        process.env.BAZEL_BINDIR || process.env.JS_BINARY__BINDIR,
        p
    )
}

// TODO(4.0): remove support for capturing stderr, stdout, and exit code. The
// js_run_binary macro now handles this in a way that does not require help from
// the launcher.
const silentOnSuccess = process.env.JS_BINARY__SILENT_ON_SUCCESS
let stdoutOutputFile = process.env.JS_BINARY__STDOUT_OUTPUT_FILE
let stderrOutputFile = process.env.JS_BINARY__STDERR_OUTPUT_FILE
let exitCodeOutputFile = process.env.JS_BINARY__EXIT_CODE_OUTPUT_FILE
if (stdoutOutputFile) {
    stdoutOutputFile = resolveCapturePath(stdoutOutputFile)
}
if (stderrOutputFile) {
    stderrOutputFile = resolveCapturePath(stderrOutputFile)
}
if (exitCodeOutputFile) {
    exitCodeOutputFile = resolveCapturePath(exitCodeOutputFile)
}

// Drop the capture-related vars from the environment so child processes (e.g. a
// nested js_binary) do not inherit them. They have been consumed above; leaking
// them would cause a nested js_binary to silently swallow its own stdout or
// write to the wrong output file.
delete process.env.JS_BINARY__STDOUT_OUTPUT_FILE
delete process.env.JS_BINARY__STDERR_OUTPUT_FILE
delete process.env.JS_BINARY__EXIT_CODE_OUTPUT_FILE
delete process.env.JS_BINARY__SILENT_ON_SUCCESS

// A stream with a declared output file is written straight to that file so that
// nothing has to run after node exits and this launcher can exec node.
//
// A stream that is only subject to silent_on_success has no final destination, so
// it is buffered in a temp file and replayed on failure.
function mktemp(name) {
    const p = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'js_binary-')), name)
    fs.writeFileSync(p, '')
    return p
}

let stdoutCapture
let stderrCapture
let stdoutCaptureIsTemp = false
let stderrCaptureIsTemp = false
if (stdoutOutputFile) {
    stdoutCapture = stdoutOutputFile
} else if (silentOnSuccess) {
    stdoutCapture = mktemp('stdout')
    stdoutCaptureIsTemp = true
}
if (stderrOutputFile) {
    stderrCapture = stderrOutputFile
} else if (silentOnSuccess) {
    stderrCapture = mktemp('stderr')
    stderrCaptureIsTemp = true
}

// FATAL and ERROR diagnostics from this launcher only go into the stderr capture
// if that capture is a temp file that will get replayed on failure. Otherwise,
// we write these straight to stderr so that they do not get lost if the action
// fails.
let logErrorCapture = stderrCaptureIsTemp ? stderrCapture : undefined

process.env.JS_BINARY__LOG_PREFIX = 'aspect_rules_js[js_binary]'

// Emit a log line to `capture`, or to the real stderr when it is unset.
//
// The bash launcher formatted these with `echo -e $(printf ...)`, whose unquoted
// command substitution collapsed every run of whitespace in the message to a
// single space. The multi-line diagnostics below rely on that to render on one
// line, so the collapsing is reproduced here.
function logTo(capture, level, message) {
    const line = `${level}: ${process.env.JS_BINARY__LOG_PREFIX}: ${message.trim().replace(/\s+/g, ' ')}\n`
    if (capture) {
        fs.appendFileSync(capture, line)
    } else {
        // Not console.error: these must be flushed before execve() below
        // replaces this process.
        fs.writeSync(2, line)
    }
}

function logfFatal(message) {
    if (process.env.JS_BINARY__LOG_FATAL) {
        logTo(logErrorCapture, 'FATAL', message)
    }
}

function logfError(message) {
    if (process.env.JS_BINARY__LOG_ERROR) {
        logTo(logErrorCapture, 'ERROR', message)
    }
}

function logfInfo(message) {
    if (process.env.JS_BINARY__LOG_INFO) {
        logTo(stderrCapture, 'INFO', message)
    }
}

function logfDebug(message) {
    if (process.env.JS_BINARY__LOG_DEBUG) {
        logTo(stderrCapture, 'DEBUG', message)
    }
}

function resolveExecrootBinPath(shortPath) {
    const bindir = process.env.BAZEL_BINDIR || process.env.JS_BINARY__BINDIR
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

// Streams captured to a declared output file were written there directly and
// need no mop up. Only the temp files that back silent_on_success do.
function mopUp(exitCode) {
    if (stderrCaptureIsTemp) {
        if (exitCode !== 0 || !silentOnSuccess) {
            fs.writeSync(2, fs.readFileSync(stderrCapture))
        }
        fs.unlinkSync(stderrCapture)
        // Stop pointing the loggers at the file that was just deleted; the
        // logfDebug below would otherwise recreate and leak it.
        stderrCapture = undefined
        logErrorCapture = undefined
    }

    if (stdoutCaptureIsTemp) {
        if (exitCode !== 0 || !silentOnSuccess) {
            fs.writeSync(1, fs.readFileSync(stdoutCapture))
        }
        fs.unlinkSync(stdoutCapture)
    }

    logfDebug(`exit code: ${exitCode}`)
}

function exitWith(exitCode) {
    mopUp(exitCode)
    process.exit(exitCode)
}

// Ends this process the way node ended, so that callers see a signal-terminated
// process rather than an interposed 128+N exit code. That is what they would
// have seen had this launcher been able to exec node instead of spawning it.
function reraiseSignal(signal, exitCode) {
    mopUp(exitCode)
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
    const manifest = process.env.RUNFILES_MANIFEST_FILE
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
if (!runfiles.startsWith('/')) {
    // Must be absolute: the runfiles path may be relative to the cwd, and we may
    // be about to change directory.
    runfiles = path.join(process.cwd(), runfiles)
}
process.env.JS_BINARY__RUNFILES = runfiles
// Set RUNFILES_DIR if not already set so that tools such as @bazel/runfiles can
// locate runfiles.
process.env.RUNFILES_DIR = process.env.RUNFILES_DIR || runfiles

// ==============================================================================
// Prepare to run main program
// ==============================================================================

let bazelOutSegment
if (process.cwd().includes('/bazel-out/')) {
    bazelOutSegment = '/bazel-out/'
} else if (process.cwd().includes('/BAZEL-~1/')) {
    bazelOutSegment = '/BAZEL-~1/'
} else if (process.cwd().includes('/bazel-~1/')) {
    bazelOutSegment = '/bazel-~1/'
}

// When the cwd is a build action execroot the bindir hangs off it (BAZEL_BINDIR resolves from the
// cwd), so the cwd is the execroot even if its path contains a "bazel-out" segment (e.g. a matching
// output base). Otherwise scan the output tree for the execroot (runfiles, or a nested js_binary in
// the bindir).
if (
    bazelOutSegment &&
    (!process.env.BAZEL_BINDIR ||
        !isDirectory(path.join(process.cwd(), process.env.BAZEL_BINDIR)))
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
        const index = process.cwd().lastIndexOf(bazelOutSegment)
        if (index < 0) {
            fs.writeSync(
                2,
                `\nERROR: ${process.env.JS_BINARY__LOG_PREFIX}: No 'bazel-out' folder found in path '${process.cwd()}'\n`
            )
            exitWith(1)
        }
        process.env.JS_BINARY__EXECROOT = process.cwd().slice(0, index)
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
        process.env.JS_BINARY__EXECROOT = process.cwd()
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
    entryPoint = resolveExecrootBinPath('js/private/test/snapshot.js')
} else {
    entryPoint = `${process.env.JS_BINARY__RUNFILES}/_main/js/private/test/snapshot.js`
}
if (!isFile(entryPoint)) {
    logfFatal(`the entry_point '${entryPoint}' not found`)
    exitWith(1)
}

const node = normalizePath('../rules_nodejs++node+nodejs_linux_amd64/bin/nodejs/bin/node')
if (node.startsWith('/')) {
    // A user may specify an absolute path to node using target_tool_path in node_toolchain
    process.env.JS_BINARY__NODE_BINARY = node
} else if (process.env.JS_BINARY__NO_RUNFILES) {
    process.env.JS_BINARY__NODE_BINARY = resolveExecrootSrcPath('../rules_nodejs++node+nodejs_linux_amd64/bin/nodejs/bin/node')
} else {
    process.env.JS_BINARY__NODE_BINARY = `${process.env.JS_BINARY__RUNFILES}/_main/../rules_nodejs++node+nodejs_linux_amd64/bin/nodejs/bin/node`
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
const npm = ''
if (npm) {
    const npmPath = normalizePath(npm)
    if (npmPath.startsWith('/')) {
        // A user may specify an absolute path to npm using npm_path in node_toolchain
        process.env.JS_BINARY__NPM_BINARY = npmPath
    } else if (process.env.JS_BINARY__NO_RUNFILES) {
        process.env.JS_BINARY__NPM_BINARY = resolveExecrootSrcPath('')
    } else {
        process.env.JS_BINARY__NPM_BINARY = `${process.env.JS_BINARY__RUNFILES}/_main/`
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
        npmWrapper = resolveExecrootSrcPath('')
    } else {
        npmWrapper = `${process.env.JS_BINARY__RUNFILES}/_main/`
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
    process.env.JS_BINARY__NODE_WRAPPER = resolveExecrootSrcPath('js/private/node_bin/node')
} else {
    process.env.JS_BINARY__NODE_WRAPPER = `${process.env.JS_BINARY__RUNFILES}/_main/js/private/node_bin/node`
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
    process.env.JS_BINARY__NODE_PATCHES = resolveExecrootSrcPath('js/private/node-bootstrap/bootstrap.cjs')
} else {
    process.env.JS_BINARY__NODE_PATCHES = `${process.env.JS_BINARY__RUNFILES}/_main/js/private/node-bootstrap/bootstrap.cjs`
}
if (!isFile(process.env.JS_BINARY__NODE_PATCHES)) {
    logfFatal(`node patches '${process.env.JS_BINARY__NODE_PATCHES}' not found`)
    exitWith(1)
}

// Change directory to user specified package if set
if (process.env.JS_BINARY__CHDIR) {
    logfDebug(
        `changing directory to user specified package ${process.env.JS_BINARY__CHDIR}`
    )
    if (process.env.JS_BINARY__CHDIR.startsWith('external/')) {
        process.chdir(resolveExecrootBinPath(process.env.JS_BINARY__CHDIR))
    } else {
        process.chdir(process.env.JS_BINARY__CHDIR)
    }
}

// Gather node options
const nodeOptions = []
function addNodeOption(value) {
    nodeOptions.push(expandEnvRefs(value))
}
addNodeOption("--preserve-symlinks-main")

// fixed_args were tokenized at analysis time. Runtime $VAR expansion still
// happens here.
const FIXED_ARGS = ["--my_arg"]

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

// Enable coverage if requested
if (process.env.COVERAGE_DIR) {
    logfDebug(`enabling v8 coverage support ${process.env.COVERAGE_DIR}`)
    process.env.NODE_V8_COVERAGE = process.env.COVERAGE_DIR
}

// Disable Node's module compile cache by default (aspect-build/rules_js#2937).
if (!process.env.NODE_COMPILE_CACHE && !process.env.NODE_DISABLE_COMPILE_CACHE) {
    process.env.NODE_DISABLE_COMPILE_CACHE = '1'
}

// Put the node wrapper directory and optionally the npm wrapper directory on the path so that
// child processes can find them.
if (npmBinDir) {
    process.env.PATH = `${npmBinDir}${path.delimiter}${process.env.PATH}`
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
    logfInfo(`PWD ${process.cwd()}`)
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

if (!expectedExitCode && !exitCodeOutputFile && !stdoutCapture && !stderrCapture) {
    // Nothing must run after node exits, so replace this process with node.
    // Signals and terminal control are then delivered directly to node instead
    // of being proxied through a child process.
    //
    // process.execve is POSIX-only and was added in Node 22.15; when it is
    // unavailable we fall through to spawning node below. A capture with a
    // declared output file also has to take that path since there is no dup2()
    // in JavaScript to point fd 1 or 2 at the file before exec.
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

// Reached when this launcher has to outlive the program: a capture with a declared
// output file needs an fd redirect that has no JavaScript equivalent, an expected
// exit code or an exit code capture needs work once the program is done, and Node
// before 22.15 has no process.execve at all. These are the paths that will keep
// spawning a second node process even once the in-process path above exists.
const child = spawn(process.env.JS_BINARY__NODE_BINARY, nodeArgs, {
    stdio: [
        'inherit',
        stdoutCapture ? fs.openSync(stdoutCapture, 'a') : 'inherit',
        stderrCapture ? fs.openSync(stderrCapture, 'a') : 'inherit',
    ],
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

    if (exitCodeOutputFile) {
        // Exit zero if the exit code was captured
        fs.writeFileSync(exitCodeOutputFile, String(result))
        exitWith(0)
    } else if (signal) {
        reraiseSignal(signal, result)
    } else {
        exitWith(result)
    }
})
