// Per-launch setup for a js_binary, run as the first --require of the node
// process, ahead of any user node_options.
//
// This file is not itself a per-process preload: it swaps its own
// process.execArgv entry for bootstrap.cjs, so child processes skip this file
// and go straight to bootstrap.cjs. Worker threads do run this file, but
// return early after requiring bootstrap.cjs.

'use strict'

const fs = require('node:fs')
const path = require('node:path')

const IS_WINDOWS = process.platform === 'win32'

// ==============================================================================
// Logging
// ==============================================================================

// Emit a log line to stderr.
//
// We use fs.writeSync rather than console.error, so that the line is flushed before a
// process.exit that may follow it.
function logTo(level, message) {
    fs.writeSync(
        2,
        `${level}: ${process.env.JS_BINARY__LOG_PREFIX}: ${message}\n`
    )
}

function logfFatal(message) {
    if (process.env.JS_BINARY__LOG_FATAL) {
        logTo('FATAL', message)
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

function fatal(message) {
    logfFatal(message)
    process.exit(1)
}

// ==============================================================================
// Helpers
// ==============================================================================

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

function checkExecutableFile(what, p) {
    if (!isFile(p)) {
        fatal(`${what} '${p}' not found`)
    }
    if (!IS_WINDOWS && !isExecutable(p)) {
        fatal(`${what} '${p}' is not executable`)
    }
}

if (process.execArgv[0] !== '--require' || !process.execArgv[1]) {
    fatal("launcher.cjs must be node's first --require")
}
const launcherPath = process.execArgv[1]
const bootstrapDir = path.dirname(launcherPath)

// ../node_bin/node and ../npm_bin/npm are files of this repository, so they sit at a
// fixed position relative to this one in every tree it can be loaded from.
const nodeWrapper = path.join(
    bootstrapDir,
    '..',
    IS_WINDOWS ? 'node_bin_windows' : 'node_bin',
    IS_WINDOWS ? 'node.bat' : 'node'
)
const npmWrapper = path.join(
    bootstrapDir,
    '..',
    IS_WINDOWS ? 'npm_bin_windows' : 'npm_bin',
    IS_WINDOWS ? 'npm.bat' : 'npm'
)
const bootstrapPath = path.join(bootstrapDir, 'bootstrap.cjs')

// Child processes that inherit process.execArgv (child_process.fork, or a spawn of
// process.execPath that passes it on) need the per-process bootstrap, not this once-per-launch
// setup, so point the entry we were loaded through at the bootstrap instead.
process.execArgv[1] = bootstrapPath

// A worker thread is started with the exec arguments node itself was given, so this preload
// runs in every worker as well. A worker is not a launch: it has no entry point in argv,
// inherits an environment that is already complete, and cannot chdir. All it needs is the same
// per-process bootstrap the main thread got.
if (!require('node:worker_threads').isMainThread) {
    require(bootstrapPath)
    return
}

// ==============================================================================
// Execroot
// ==============================================================================

function withSlashes(p) {
    return IS_WINDOWS ? p.replace(/\\/g, '/') : p
}

// The directory the launcher script was started in.
//
// The launcher script generally cds into BAZEL_BINDIR before starting node, and indicates this
// by exporting JS_BINARY__CHANGED_TO_BINDIR. If that variable is set then we step back out to
// where the script started.
function launchCwd() {
    const cwd = process.cwd()
    if (!changedToBindir) {
        return cwd
    }
    const depth = process.env.BAZEL_BINDIR.split('/').filter(
        (segment) => segment && segment !== '.'
    ).length
    return depth ? path.resolve(cwd, Array(depth).fill('..').join('/')) : cwd
}

const changedToBindir = !!process.env.JS_BINARY__CHANGED_TO_BINDIR
// Unset this so that it does not influence any child processes.
delete process.env.JS_BINARY__CHANGED_TO_BINDIR

const startCwd = launchCwd()
const slashCwd = withSlashes(startCwd)
const bindir = process.env.BAZEL_BINDIR
const bazelOutSegment = ['/bazel-out/', '/BAZEL-~1/', '/bazel-~1/'].find(
    (segment) => slashCwd.includes(segment)
)

// A parent js_binary process hands its own execroot down when it asks for an execroot
// entry point, because the entry point it resolved is in that tree, not in ours.
const inheritedExecroot =
    process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT &&
    process.env.JS_BINARY__EXECROOT
if (inheritedExecroot) {
    logfDebug(
        `inheriting JS_BINARY__EXECROOT ${inheritedExecroot} from parent js_binary process as JS_BINARY__USE_EXECROOT_ENTRY_POINT is set`
    )
}

// When the launch directory is a build action execroot the bindir hangs off it (BAZEL_BINDIR
// resolves from the launch directory), so it is the execroot even if its path contains a
// "bazel-out" segment (e.g. a matching output base). Otherwise scan the output tree for the
// execroot (runfiles, or a nested js_binary in the bindir).
if (bazelOutSegment && (!bindir || !isDirectory(path.join(startCwd, bindir)))) {
    if (!inheritedExecroot) {
        // We are in runfiles and we don't yet know the execroot; strip from the last
        // "bazel-out" segment.
        process.env.JS_BINARY__EXECROOT = startCwd.slice(
            0,
            slashCwd.lastIndexOf(bazelOutSegment)
        )
    }
} else {
    if (!inheritedExecroot) {
        // We are in execroot or in some other context all together such as a nodejs_image
        // or a manually run js_binary.
        process.env.JS_BINARY__EXECROOT = startCwd
    }

    // The launcher script only changes directory when the bindir is there to change into, so
    // that it leaves a runfiles tree alone. Reaching here means it was supposed to and could
    // not, which is a broken launch rather than one of the cases above.
    if (!process.env.JS_BINARY__NO_CD_BINDIR && !changedToBindir) {
        if (!bindir) {
            fatal(
                'BAZEL_BINDIR must be set in environment to the makevar $(BINDIR) in js_binary ' +
                    'build actions (which run in the execroot) so that build actions can change ' +
                    'directories to always run out of the root of the Bazel output tree. See ' +
                    'https://docs.bazel.build/versions/main/be/make-variables.html#predefined_variables. ' +
                    "This is automatically set by 'js_run_binary' " +
                    '(https://github.com/aspect-build/rules_js/blob/main/docs/js_run_binary.md) which ' +
                    'is the recommended rule to use for using a js_binary as the tool of a build ' +
                    'action. If you are invoking a js_binary directly from your own custom rule ' +
                    "implementation, use the 'js_binary_lib.run_binary_action' helper " +
                    '(https://github.com/aspect-build/rules_js/blob/main/js/libs.bzl) instead of ' +
                    'calling ctx.actions.run yourself so that BAZEL_BINDIR is set correctly. If this ' +
                    "is not a build action you can set the BAZEL_BINDIR to '.' instead to supress " +
                    'this error. For more context on this design decision, please read the ' +
                    'aspect_rules_js README ' +
                    'https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs.'
            )
        }
        fatal(
            `BAZEL_BINDIR '${bindir}' is not a directory in '${startCwd}', so the launcher could not change into the root of the Bazel output tree`
        )
    }
}

// ==============================================================================
// Validate the launch
// ==============================================================================

if (process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT) {
    if (
        !process.env.JS_BINARY__COPY_DATA_TO_BIN &&
        !process.env
            .JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN
    ) {
        fatal(
            'Expected js_binary copy_data_to_bin to be True when js_run_binary use_execroot_entry_point is True. ' +
                'To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary'
        )
    }
}

if (process.env.JS_BINARY__NO_RUNFILES) {
    if (
        !process.env.JS_BINARY__COPY_DATA_TO_BIN &&
        !process.env
            .JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN
    ) {
        fatal(
            'Expected js_binary copy_data_to_bin to be True when js_binary use_execroot_entry_point is True. ' +
                'To disable this validation you can set allow_execroot_entry_point_with_no_copy_data_to_bin to True in js_run_binary'
        )
    }
}

// bash resolved the entry point and handed it to node as the main module; node has
// already made it absolute, but has not tried to load it yet.
const entryPoint = process.argv[1]
if (!entryPoint || !isFile(entryPoint)) {
    fatal(`the entry_point '${entryPoint}' not found`)
}

let npmBinDir
if (process.env.JS_BINARY__NPM_BINARY) {
    checkExecutableFile('npm binary', process.env.JS_BINARY__NPM_BINARY)
    checkExecutableFile('npm wrapper', npmWrapper)
    npmBinDir = path.dirname(npmWrapper)
}

checkExecutableFile('node wrapper', nodeWrapper)
process.env.JS_BINARY__NODE_WRAPPER = nodeWrapper

if (!isFile(bootstrapPath)) {
    fatal(`bootstrap '${bootstrapPath}' not found`)
}
process.env.JS_BINARY__NODE_PATCHES = bootstrapPath

// ==============================================================================
// Environment for the program and its children
// ==============================================================================

// Configure JS_BINARY__FS_PATCH_ROOTS for the node fs patches applied by bootstrap.cjs.
// Don't override JS_BINARY__FS_PATCH_ROOTS if already set by an outer js_binary in case a
// js_binary such as js_run_devserver runs another js_binary tool.
if (!process.env.JS_BINARY__FS_PATCH_ROOTS) {
    process.env.JS_BINARY__FS_PATCH_ROOTS = `${process.env.JS_BINARY__EXECROOT}${path.delimiter}${process.env.JS_BINARY__RUNFILES}`
}

// Put the node wrapper directory and optionally the npm wrapper directory on the path so that
// child processes can find them.
let PATH = process.env.PATH || ''
if (npmBinDir) {
    PATH = `${npmBinDir}${path.delimiter}${PATH}`
}
process.env.PATH = `${path.dirname(nodeWrapper)}${path.delimiter}${PATH}`

// ==============================================================================
// Logs
// ==============================================================================

if (process.env.JS_BINARY__LOG_DEBUG) {
    logfDebug(`PATH ${process.env.PATH}`)
    for (const name of [
        'BAZEL_BINDIR',
        'BAZEL_BUILD_FILE_PATH',
        'BAZEL_COMPILATION_MODE',
        'BAZEL_INFO_FILE',
        'BAZEL_PACKAGE',
        'BAZEL_TARGET_CPU',
        'BAZEL_TARGET_NAME',
        'BAZEL_VERSION_FILE',
        'BAZEL_WORKSPACE',
    ]) {
        if (process.env[name]) {
            logfDebug(`${name} ${process.env[name]}`)
        }
    }
    logfDebug(
        `JS_BINARY__FS_PATCH_ROOTS ${process.env.JS_BINARY__FS_PATCH_ROOTS}`
    )
    logfDebug(`JS_BINARY__NODE_PATCHES ${process.env.JS_BINARY__NODE_PATCHES}`)
    logfDebug(`JS_BINARY__NODE_OPTIONS ${process.execArgv.slice(2).join(' ')}`)
    for (const name of [
        'JS_BINARY__BINDIR',
        'JS_BINARY__BUILD_FILE_PATH',
        'JS_BINARY__COMPILATION_MODE',
        'JS_BINARY__NODE_BINARY',
        'JS_BINARY__NODE_WRAPPER',
    ]) {
        logfDebug(`${name} ${process.env[name] || ''}`)
    }
    if (process.env.JS_BINARY__NPM_BINARY) {
        logfDebug(`JS_BINARY__NPM_BINARY ${process.env.JS_BINARY__NPM_BINARY}`)
    }
    if (process.env.JS_BINARY__NO_RUNFILES) {
        logfDebug(
            `JS_BINARY__NO_RUNFILES ${process.env.JS_BINARY__NO_RUNFILES}`
        )
    }
    for (const name of [
        'JS_BINARY__PACKAGE',
        'JS_BINARY__TARGET_CPU',
        'JS_BINARY__TARGET_NAME',
        'JS_BINARY__WORKSPACE',
    ]) {
        logfDebug(`${name} ${process.env[name] || ''}`)
    }
    logfDebug(`js_binary entry point ${entryPoint}`)
    if (process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT) {
        logfDebug(
            `JS_BINARY__USE_EXECROOT_ENTRY_POINT ${process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT}`
        )
    }
}

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
// Per-process setup: fs patches, coverage
// ==============================================================================

// Required by the same string every other node process under this launch will be
// given, so that it is one module in the require cache however it is reached.
require(bootstrapPath)

// ==============================================================================
// chdir
// ==============================================================================

// The chdir option on js_binary or js_run_binary. We cd after the bootstrap rather than before
// it, because coverage.cjs snapshots the directory the launcher started in and resolves
// COVERAGE_DIR against it.
if (process.env.JS_BINARY__CHDIR) {
    let dir = process.env.JS_BINARY__CHDIR
    // chdir is relative to the root of the output tree, where an external repository's package sits
    // under "external/<repo>". The runfiles tree instead gives every repository a top-level
    // directory beside our own, so re-point the path there rather than leaving the tree. Bazel sets
    // TEST_SRCDIR for a test and BUILD_WORKSPACE_DIRECTORY for `bazel run`, and these are the two
    // situations where we will be in the runfiles tree.
    if (
        (process.env.TEST_SRCDIR || process.env.BUILD_WORKSPACE_DIRECTORY) &&
        dir.startsWith('external/')
    ) {
        dir = '../' + dir.slice('external/'.length)
    }
    try {
        process.chdir(dir)
    } catch (e) {
        fatal(`could not change directory to '${dir}': ${e.message}`)
    }
    // process.chdir() does not maintain PWD, so let's update it here.
    process.env.PWD = process.cwd()
    // Prevent child processes and worker threads from attempting to cd a second time.
    delete process.env.JS_BINARY__CHDIR
}
