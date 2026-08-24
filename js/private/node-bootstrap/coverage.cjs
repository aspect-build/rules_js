// Code coverage
//
// Generate the lcov report when this process exits. The test action is the only place the
// V8 coverage data and the instrumented sources are both present, and this hook is the
// only thing that runs there once the launcher script `exec`s node. coverage.js is run in
// its own process: it is async, it chdir()s, and running it here would land its own
// execution in this process's V8 profile. See #2901.
//
// bootstrap.cjs requires this module only when JS_BINARY__COVERAGE_REPORT is set, which
// js_binary.bzl does for a test target under `bazel coverage` only; the variable holds
// coverage.js's runfiles-relative path.

// Child node processes re-enter bootstrap.cjs with an inherited environment. Only the root
// process reports, once every child has exited and written its profile.
const { JS_BINARY__COVERAGE_REPORT } = process.env
delete process.env.JS_BINARY__COVERAGE_REPORT

// Snapshot the environment and cwd now: the program under test may mutate either before it
// exits, and the reporter must see what the launcher set up.
//
// NODE_V8_COVERAGE is blanked so the reporter writes no profile of its own alongside the
// ones it reads. It has to be emptied rather than deleted: child_process always propagates
// NODE_V8_COVERAGE from the parent, and only skips doing so when the env passed to it has
// the key as a property.
const env = {
    ...process.env,
    JS_COVERAGE__RUNFILES: process.env.JS_BINARY__RUNFILES,
    NODE_V8_COVERAGE: '',
}
const cwd = process.cwd()
// Not process.execPath, which bootstrap.cjs patched to the node wrapper; that would
// re-apply the bootstrap in the reporter process.
const nodeBinary = process.env.JS_BINARY__NODE_BINARY
const report = require('node:path').resolve(
    process.env.JS_BINARY__RUNFILES,
    JS_BINARY__COVERAGE_REPORT
)

// NB: this runs before any 'exit' listener the program registers, whereas the launcher used
// to run after the process was gone. A program that writes its own report to
// COVERAGE_OUTPUT_FILE from an 'exit' listener therefore also gets a report generated here.
// What ends up published is unchanged: the merger prefers the program's own report, except
// under split post-processing where bazel discards it and ours is published instead. For
// the same reason the profile is snapshotted before those listeners run, so code a program
// executes from its own 'exit' listener is reported as uncovered.
process.on('exit', function onExitCoverageReport() {
    try {
        // A test reporting its own coverage owns it, except under split
        // post-processing, where bazel drops what the test wrote.
        if (env.SPLIT_COVERAGE_POST_PROCESSING !== '1' && env.COVERAGE_OUTPUT_FILE) {
            const stat = require('node:fs').statSync(env.COVERAGE_OUTPUT_FILE, {
                throwIfNoEntry: false,
            })
            if (stat && stat.size > 0) return
        }
        if (!require('node:fs').existsSync(report)) {
            // Report empty coverage rather than fail an otherwise passing test.
            logError(
                `coverage report generator '${report}' not found; code coverage requires a runfiles tree`
            )
            return
        }
        // node writes this process's own profile during teardown, which happens after
        // this handler runs, so flush it here. Deliberately no v8.stopCoverage(): node's
        // teardown asks V8 for coverage regardless, and errors out once it has stopped.
        require('node:v8').takeCoverage()
        const { status, error } = require('node:child_process').spawnSync(
            nodeBinary,
            [report],
            { cwd, env, stdio: 'inherit' }
        )
        if (error || status !== 0) {
            throw error || new Error(`exit code ${status}`)
        }
    } catch (e) {
        // Throwing here would skip every later 'exit' listener, including the program's own.
        logError(`coverage report generation failed: ${e.message}`)
        process.exitCode = 1
    }
})

function logError(message) {
    if (env.JS_BINARY__LOG_ERROR) {
        console.error(`ERROR: ${env.JS_BINARY__LOG_PREFIX}: ${message}`)
    }
}
