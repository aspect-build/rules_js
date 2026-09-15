// Helpers shared by the two files that start a js_binary: js_binary.cjs.tpl, the generated
// launcher the hermetic stub runs, and launcher.cjs, the per-launch preload that both
// launchers load as node's first --require.
//
// Nothing here may do anything at load time. The generated launcher requires this file before
// it has set up any of the environment, so a side effect here would run too early to be
// correct and too far from its cause to be found.

'use strict'

const fs = require('node:fs')

const IS_WINDOWS = process.platform === 'win32'

// ==============================================================================
// Logging
// ==============================================================================

// Emit a log line to stderr.
//
// We use fs.writeSync rather than console.error, so that the line is flushed before a
// process.exit, or the execve that replaces the generated launcher, can follow it.
//
// The message is collapsed onto one line: several of these are long enough to be written
// across multiple source lines, and a caller that logs an exception has no control over
// what is in it.
function log(level, message) {
    const collapsed = message.trim().replace(/\s+/g, ' ')
    fs.writeSync(
        2,
        `${level}: ${process.env.JS_BINARY__LOG_PREFIX}: ${collapsed}\n`
    )
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

// ==============================================================================
// Paths
// ==============================================================================

// Normalizes paths when running on Windows.
//
// Example:
// C:\Users\XUser\_bazel_XUser\7q7kkv32\execroot\A\b\C -> C:/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C
//
// Only the separator changes. Node accepts forward slashes on Windows, so the separator
// rewrite is all that is needed and the comparisons in the callers can stay written with '/'.
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

module.exports = {
    IS_WINDOWS,
    checkExecutableFile,
    fatal,
    isDirectory,
    isExecutable,
    isFile,
    log,
    logDebug,
    logError,
    logFatal,
    logInfo,
    withSlashes,
}
