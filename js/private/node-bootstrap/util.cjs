// Helpers shared by the two files that start a js_binary: js_binary.cjs.tpl, the generated
// launcher the hermetic stub runs, and launcher.cjs, the per-launch preload that both
// launchers load as node's first --require.
//
// Nothing here may do anything at load time: the generated launcher requires this file
// before it has set up any of the environment.

'use strict'

const fs = require('node:fs')
const path = require('node:path')

const IS_WINDOWS = process.platform === 'win32'

// ==============================================================================
// Logging
// ==============================================================================

// Emit a log line to stderr.
//
// We use fs.writeSync rather than console.error, so that the line is flushed before
// the process exits.
function log(level, message) {
    fs.writeSync(2, `${level}: ${process.env.JS_BINARY__LOG_PREFIX}: ${message}\n`)
}

function logFatal(message) {
    if (process.env.JS_BINARY__LOG_FATAL) {
        log('FATAL', message)
    }
}

function logError(message) {
    if (process.env.JS_BINARY__LOG_ERROR) {
        log('ERROR', message)
    }
}

function logInfo(message) {
    if (process.env.JS_BINARY__LOG_INFO) {
        log('INFO', message)
    }
}

function logDebug(message) {
    if (process.env.JS_BINARY__LOG_DEBUG) {
        log('DEBUG', message)
    }
}

function fatal(message) {
    logFatal(message)
    process.exit(1)
}

function exitWith(exitCode) {
    logDebug(`exit code: ${exitCode}`)
    process.exit(exitCode)
}

// ==============================================================================
// Environment
// ==============================================================================

// The bash launcher splices env values, node options and fixed args into double-quoted
// strings, so users rely on shell parameter expansion happening at launch time; for example
// examples/stack_traces passes
// node_options = ["--require", "$$RUNFILES_DIR/..."].
// Only $VAR / ${VAR} expansion is reproduced here: no command substitution, and no
// re-splitting on whitespace.
//
// Naming a variable that is not set is fatal, as it is for the bash launcher under
// `set -o nounset`. A variable that is set to the empty string expands to it, which is
// also what bash does.
function expandEnvRefs(value) {
    return value.replace(
        /\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))/g,
        (_match, braced, bare) => {
            const name = braced || bare
            const expanded = process.env[name]
            if (expanded === undefined) {
                fatal(`${name}: unbound variable`)
            }
            return expanded
        }
    )
}

function setEnv(name, value) {
    process.env[name] = expandEnvRefs(value)
}

// An empty value counts as unset, matching the `[[ -z ]]` test the bash launcher
// writes for the same env entry.
function setEnvIfUnset(name, value) {
    if (!process.env[name]) {
        process.env[name] = expandEnvRefs(value)
    }
}

// ==============================================================================
// Paths
// ==============================================================================

// Node accepts forward slashes on Windows, so rewriting the separator is all that is needed
// to let the comparisons in the callers stay written with '/'.
function withSlashes(p) {
    return IS_WINDOWS ? p.replace(/\\/g, '/') : p
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

function checkExecutableFile(what, p) {
    if (!isFile(p)) {
        fatal(`${what} '${p}' not found`)
    }
    if (!IS_WINDOWS && !isExecutable(p)) {
        fatal(`${what} '${p}' is not executable`)
    }
}

// Resolve a short path in the Bazel output tree against the execroot the launcher was started in.
function resolveExecrootBinPath(execroot, shortPath) {
    if (!process.env.BAZEL_BINDIR) {
        logFatal(
            'BAZEL_BINDIR must be set in the environment to the makevar $(BINDIR) to resolve a path in the Bazel output tree'
        )
        exitWith(1)
    }
    if (shortPath.startsWith('../')) {
        return `${execroot}/${process.env.BAZEL_BINDIR}/external/${shortPath.slice(3)}`
    }
    return `${execroot}/${process.env.BAZEL_BINDIR}/${shortPath}`
}

function resolveExecrootSrcPath(execroot, shortPath) {
    if (shortPath.startsWith('../')) {
        return `${execroot}/external/${shortPath.slice(3)}`
    }
    return `${execroot}/${shortPath}`
}

// Resolve a toolchain file that is a file of this workspace or another repository
// in the runfiles tree, or an absolute path a user set in node_toolchain.
function resolveToolchainPath(execroot, workspaceName, file) {
    // Only an absolute path can arrive with backslashes, from a node_toolchain a
    // user configured; a short path baked in at analysis time uses '/' on every platform.
    if (path.isAbsolute(file)) {
        return withSlashes(file)
    }
    if (process.env.JS_BINARY__NO_RUNFILES) {
        return resolveExecrootSrcPath(execroot, file)
    }
    return `${process.env.JS_BINARY__RUNFILES}/${workspaceName}/${file}`
}

// ==============================================================================
// Signals
// ==============================================================================

// Node does not forward termination signals to any child process, so the signals are
// trapped and forwarded manually.
//
// Each signal stops being forwarded as soon as it has been forwarded once, so a repeat of
// it terminates the launcher rather than being swallowed.
function forwardSignals(child) {
    const handlers = new Map()

    // With no listener left, node restores the signal's default disposition, which is what
    // lets it terminate this process.
    function stopForwarding(signal) {
        const handler = handlers.get(signal)
        if (handler) {
            handlers.delete(signal)
            process.off(signal, handler)
        }
    }

    for (const signal of ['SIGTERM', 'SIGINT']) {
        const handler = () => {
            stopForwarding(signal)
            try {
                child.kill(signal)
            } catch {
                // the child already exited
            }
        }
        handlers.set(signal, handler)
        process.on(signal, handler)
    }

    return {
        // Ends this process the way node ended, so that callers see a signal-terminated
        // process rather than an interposed 128+N exit code.
        reraise(signal, exitCode) {
            logDebug(`exit code: ${exitCode}`)
            // The listener would otherwise forward to the defunct child process.
            stopForwarding(signal)
            process.kill(process.pid, signal)
            // Only reached if the signal turned out not to be fatal after all.
            process.exit(exitCode)
        },
    }
}

module.exports = {
    IS_WINDOWS,
    checkExecutableFile,
    exitWith,
    expandEnvRefs,
    fatal,
    forwardSignals,
    isDirectory,
    isExecutable,
    isFile,
    log,
    logDebug,
    logError,
    logFatal,
    logInfo,
    resolveExecrootBinPath,
    resolveToolchainPath,
    setEnv,
    setEnvIfUnset,
    withSlashes,
}
