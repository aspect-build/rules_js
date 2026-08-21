const patchfs = require('./fs.cjs').patcher
const {
    JS_BINARY__FS_PATCH_ROOTS,
    JS_BINARY__LOG_DEBUG,
    JS_BINARY__LOG_PREFIX,
    JS_BINARY__NODE_WRAPPER,
    JS_BINARY__PATCH_NODE_FS,
} = process.env

// Keep a count of how many times these patches are applied; this should reflect the depth
// of child processes in the default case where a child process inherits process.env since
// child processes need to re-apply the patches. This is here primarily for testing but it
// could also be useful for debugging.
if (!process.env.JS_BINARY__NODE_PATCHES_DEPTH) {
    process.env.JS_BINARY__NODE_PATCHES_DEPTH = '.'
} else {
    process.env.JS_BINARY__NODE_PATCHES_DEPTH += '.'
}

// subprocess patch
if (process.platform == 'win32') {
    // FIXME: need to make an exe, or run in a shell so we can use .bat
} else {
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: overriding process.execPath to node wrapper path ${JS_BINARY__NODE_WRAPPER}`
        )
    }
    process.argv[0] = process.execPath = JS_BINARY__NODE_WRAPPER
}

// fs patches
if (
    JS_BINARY__PATCH_NODE_FS &&
    JS_BINARY__PATCH_NODE_FS != '0' &&
    JS_BINARY__FS_PATCH_ROOTS
) {
    const roots = JS_BINARY__FS_PATCH_ROOTS.split(':')
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `DEBUG: ${JS_BINARY__LOG_PREFIX}: node fs patches will be applied with roots: ${roots}`
        )
    }
    patchfs(roots)
}

// Code coverage
//
// Generate the lcov report when this process exits. The test action is the only place
// the V8 coverage data and the instrumented sources are both present, and this hook is
// the only thing that runs there once the launcher script `exec`s node. coverage.js is
// run in its own process: it is async, it chdir()s, and running it here would land its
// own execution in this process's V8 profile. See #2901.
//
// JS_BINARY__COVERAGE_REPORT is set by js_binary.bzl for a test target under
// `bazel coverage` only, and holds the runfiles-relative path of coverage.js.
const { JS_BINARY__COVERAGE_REPORT } = process.env
if (JS_BINARY__COVERAGE_REPORT) {
    // Child node processes re-enter this bootstrap with an inherited environment. Only
    // the root process reports, once every child has exited and written its profile.
    delete process.env.JS_BINARY__COVERAGE_REPORT
}
if (JS_BINARY__COVERAGE_REPORT && process.env.COVERAGE_DIR) {
    // Snapshot the environment and cwd now: the program under test may mutate either
    // before it exits, and the reporter must see what the launcher set up.
    //
    // NODE_V8_COVERAGE is blanked so the reporter writes no profile of its own
    // alongside the ones it reads. It has to be emptied rather than deleted:
    // child_process always propagates NODE_V8_COVERAGE from the parent, and only skips
    // doing so when the env passed to it has the key as a property.
    const env = {
        ...process.env,
        JS_COVERAGE__RUNFILES: process.env.JS_BINARY__RUNFILES,
        NODE_V8_COVERAGE: '',
    }
    const cwd = process.cwd()
    // Not process.execPath, which was patched above to the node wrapper; that would
    // re-apply this bootstrap in the reporter process.
    const nodeBinary = process.env.JS_BINARY__NODE_BINARY
    const report = require('path').resolve(
        process.env.JS_BINARY__RUNFILES,
        JS_BINARY__COVERAGE_REPORT
    )

    // NB: this runs before any 'exit' listener the program registers, whereas the
    // launcher used to run after the process was gone. A program that writes its own
    // report to COVERAGE_OUTPUT_FILE from an 'exit' listener therefore also gets a
    // report generated here. What ends up published is unchanged: the merger prefers
    // the program's own report, except under split post-processing where bazel discards
    // it and ours is published instead.
    process.on('exit', (code) => {
        // A test reporting its own coverage owns it, except in split mode where bazel
        // drops it.
        if (
            env.SPLIT_COVERAGE_POST_PROCESSING !== '1' &&
            env.COVERAGE_OUTPUT_FILE
        ) {
            const stat = require('fs').statSync(env.COVERAGE_OUTPUT_FILE, {
                throwIfNoEntry: false,
            })
            if (stat && stat.size > 0) return
        }
        try {
            if (!require('fs').existsSync(report)) {
                // Report empty coverage rather than fail an otherwise passing test.
                logError(
                    `coverage report generator '${report}' not found; code coverage requires a runfiles tree`
                )
                return
            }
            // node writes this process's own profile during teardown, which happens
            // after this handler runs, so flush it here. Deliberately no
            // v8.stopCoverage(): node's teardown asks V8 for coverage regardless and
            // would print an error once coverage has been stopped.
            require('v8').takeCoverage()
            const { status, error } = require('child_process').spawnSync(
                nodeBinary,
                [report],
                { cwd, env, stdio: 'inherit' }
            )
            if (error || status !== 0) {
                throw error || new Error(`exit code ${status}`)
            }
        } catch (e) {
            // Throwing here would skip every later 'exit' listener, including the
            // program's own.
            logError(`coverage report generation failed: ${e.message}`)
            process.exitCode = 1
        }
    })
}

function logError(message) {
    if (process.env.JS_BINARY__LOG_ERROR) {
        console.error(`ERROR: ${JS_BINARY__LOG_PREFIX}: ${message}`)
    }
}
