// Code coverage
//
// Collects this process's V8 coverage, and, for a test that reports, runs coverage.js on
// exit to turn the collected profiles into an lcov report.
//
// We enable collection via the inspector rather than by setting the NODE_V8_COVERAGE
// environment variable. This allows us to start collection in-process without relying on any
// shell script logic to run beforehand.
//
// The report is generated here because the test action is the only place the profiles and
// the instrumented sources are both present, and in its own process because coverage.js is
// async, chdir()s, and would otherwise land in this process's own profile. See #2901.
const { JS_BINARY__LOG_ERROR, JS_BINARY__LOG_PREFIX } = process.env

const collecting = startCollection()

// Child node processes re-enter bootstrap.cjs with an inherited environment. Only the root
// process reports, once every child has exited and written its profile.
const { JS_BINARY__COVERAGE_REPORT } = process.env
delete process.env.JS_BINARY__COVERAGE_REPORT
if (JS_BINARY__COVERAGE_REPORT) {
    reportOnExit(JS_BINARY__COVERAGE_REPORT)
}

// Registers the exit hook that runs coverage.js, the executable that turns the V8 profiles in
// COVERAGE_DIR into the lcov report the _lcov_merger publishes.
function reportOnExit(reportPath) {
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
        reportPath
    )

    // This listener is registered by a --require preload, so it runs before any
    // 'exit' listener the program itself registers.  takeCoverage() below
    // therefore snapshots the profile before those listeners run, and code the
    // program executes from one of them is reported as uncovered.
    process.on('exit', function onExitCoverageReport() {
        try {
            const fs = require('node:fs')
            const { spawnSync } = require('node:child_process')

            // A test reporting its own coverage owns it, except under split
            // post-processing, where bazel drops what the test wrote.
            if (
                env.SPLIT_COVERAGE_POST_PROCESSING !== '1' &&
                env.COVERAGE_OUTPUT_FILE
            ) {
                const stat = fs.statSync(env.COVERAGE_OUTPUT_FILE, {
                    throwIfNoEntry: false,
                })
                if (stat && stat.size > 0) return
            }
            if (!fs.existsSync(report)) {
                // Report empty coverage rather than fail an otherwise passing test.
                logError(
                    `coverage report generator '${report}' not found; code coverage requires a runfiles tree`
                )
                return
            }
            // When we collect, our own profile is already on disk: startCollection
            // registered its exit listener before this one. node instead writes it during
            // teardown, after this handler, so ask for it here. Deliberately no
            // v8.stopCoverage(): node's teardown asks V8 for coverage regardless, and
            // errors out once it has stopped.
            if (!collecting) {
                require('node:v8').takeCoverage()
            }
            const { status, error } = spawnSync(nodeBinary, [report], {
                cwd,
                env,
                stdio: 'inherit',
            })
            if (error || status !== 0) {
                throw error || new Error(`exit code ${status}`)
            }
        } catch (e) {
            // Throwing here would skip every later 'exit' listener, including the program's own.
            logErrorAndFail(`coverage report generation failed: ${e.message}`)
        }
    })
}

// Starts a V8 precise coverage session for this process, unless node is already collecting.
// Returns whether we are the collector.
function startCollection() {
    if (!process.env.COVERAGE_DIR || process.env.NODE_V8_COVERAGE) {
        return false
    }

    const path = require('node:path')
    const { mkdirSync, writeFileSync } = require('node:fs')

    // A node without inspector support, or a program that already holds the session,
    // makes this throw. Report empty coverage rather than take down a program that would
    // otherwise have run: this preload is in every js_binary under `bazel coverage`, so a
    // throw here fails the target before its own code starts.
    let session
    try {
        session = new (require('node:inspector').Session)()
        session.connect()
        // post() reports a command failure through its callback and drops it entirely
        // without one. The callback is synchronous, so this rethrows into the catch below.
        const post = (method, params) => {
            let failure
            session.post(method, params, (err) => {
                failure = err
            })
            if (failure) {
                throw failure
            }
        }
        post('Profiler.enable')
        post('Profiler.startPreciseCoverage', {
            callCount: true,
            detailed: true,
        })
    } catch (e) {
        logError(`v8 coverage collection unavailable: ${e.message}`)
        return false
    }

    // Resolve now: bootstrap.cjs may chdir this process later, and node itself resolves
    // NODE_V8_COVERAGE against the directory it started in.
    const dir = path.resolve(process.env.COVERAGE_DIR)

    // Enable coverage for all child processes.
    process.env.NODE_V8_COVERAGE = dir

    function flush() {
        // The callback is synchronous, which is what makes this usable from an exit listener.
        session.post('Profiler.takePreciseCoverage', (err, coverage) => {
            try {
                if (err) {
                    throw err
                }
                mkdirSync(dir, { recursive: true })
                // The name node itself uses: pid, timestamp, thread id. Only one collector
                // ever runs in a thread, so no two can pick the same name.
                const { threadId } = require('node:worker_threads')
                const name = `coverage-${process.pid}-${Date.now()}-${threadId}.json`
                writeFileSync(
                    path.join(dir, name),
                    JSON.stringify({
                        result: coverage.result,
                        timestamp: Date.now(),
                        'source-map-cache': sourceMapCache(coverage.result),
                    })
                )
            } catch (e) {
                logErrorAndFail(`v8 coverage collection failed: ${e.message}`)
            }
        })
        session.disconnect()
    }

    process.on('exit', flush)
    return true
}

// The source maps node recorded for the scripts in this profile, in the shape node writes
// alongside its own: {<script url>: {data, lineLengths}}. The reporter needs them to map V8
// offsets in generated code back to the original source. It re-reads a //# sourceMappingURL
// from disk on its own, so this only matters for a runtime transpiler such as ts-node, which
// compiles from memory and leaves nothing on disk to read; there the map is unrecoverable
// without this, and the reporter silently attributes execution to the wrong lines rather
// than reporting none.
//
// node populates this cache as it compiles each module, gated on NODE_V8_COVERAGE, which
// startCollection sets above before any of the program is compiled. That is the same gate
// node's own writer relies on, and it does not turn on source-mapped stack traces.
function sourceMapCache(result) {
    const { findSourceMap } = require('node:module')
    const cache = {}
    for (const { url } of result) {
        // Skip node's own builtins, and anything not compiled from a file.
        if (!url || !url.startsWith('file://')) {
            continue
        }
        try {
            const map = findSourceMap(url)
            if (map) {
                cache[url] = { data: map.payload, lineLengths: map.lineLengths }
            }
        } catch {
            // A script whose map cannot be recovered is reported unmapped, as it would
            // have been without this.
        }
    }
    return cache
}

function logError(message) {
    if (JS_BINARY__LOG_ERROR) {
        console.error(`ERROR: ${JS_BINARY__LOG_PREFIX}: ${message}`)
    }
}

// Fail the target, without masking an exit code the program has already chosen.
function logErrorAndFail(message) {
    logError(message)
    if (!process.exitCode) {
        process.exitCode = 1
    }
}
