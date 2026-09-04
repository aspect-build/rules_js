import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// Runs in the test action, the only place the V8 data and the instrumented sources are
// both present. coverage.sh.tpl reads back this exact filename; keep them in sync.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.lcov')

const debug = !!process.env.JS_BINARY__LOG_DEBUG
const timings = []

// Report generation is charged against the test's own timeout, so when something is slow
// this is the only place that says which part. See docs/troubleshooting.md.
function logDebug(message) {
    if (debug) {
        console.error(`DEBUG: ${process.env.JS_BINARY__LOG_PREFIX}: ${message}`)
    }
}

function timed(label, fn) {
    if (!debug) return fn()
    const start = process.hrtime.bigint()
    const value = fn()
    timings.push(`${label}=${(Number(process.hrtime.bigint() - start) / 1e6).toFixed(0)}ms`)
    return value
}

const started = process.hrtime.bigint()

const include = fs
    .readFileSync(process.env.COVERAGE_MANIFEST)
    .toString('utf8')
    .split('\n')
    .filter((f) => f != '')

// TODO: can or should we instrument files from other repositories as well?
// if so then the path.join call below will yield invalid paths since files will have external/wksp as their prefix.
const pwd = path.join(
    process.env.JS_COVERAGE__RUNFILES,
    process.env.TEST_WORKSPACE
)
process.chdir(pwd)

// Same list as COVERAGE_EXTENSIONS in js/private/coverage/extensions.bzl, which is what
// decides the contents of COVERAGE_MANIFEST. c8 drops a manifest entry whose extension is
// not listed here, so the two must agree; c8's own default list has neither .mts nor .cts.
const extensions = new Set(['.mjs', '.mts', '.cjs', '.cts', '.ts', '.js', '.jsx', '.tsx'])

const report = new Report({
    include: include,
    exclude: include.length === 0 ? ['**'] : [],
    extension: [...extensions],
    reportsDirectory: process.env.COVERAGE_DIR,
    tempDirectory: process.env.COVERAGE_DIR,
    resolve: '',
    src: pwd,
    all: true,
    reporter: ['lcovonly'],
})

// Bazel already computed the exact set of instrumented files and handed it to us in
// COVERAGE_MANIFEST, so membership is a lookup. c8 otherwise answers the same question by
// globbing the whole runfiles tree under `src` and minimatching every hit against every
// manifest entry -- and TestExclude expands each entry into two patterns -- which is
// O(files in runfiles x manifest entries) in each test action. Both hooks below replace
// that with the set Bazel already knows.
const instrumented = new Set(include.map((f) => path.resolve(pwd, f)))

report.exclude.shouldInstrument = function shouldInstrument(filename) {
    const resolved = path.resolve(pwd, filename)
    return extensions.has(path.extname(resolved)) && instrumented.has(resolved)
}

// `all: true` reports files no test executed. Those are exactly the manifest entries no
// V8 profile mentioned, so the directory walk this replaces could only ever have found a
// subset of them. Non-existent entries must be filtered out here rather than left to
// c8: it stats each returned path without guarding, where the glob simply never yielded
// a path that was not on disk.
report.exclude.globSync = function globSync() {
    return timed('uncovered_scan', () =>
        include.filter((f) => fs.existsSync(path.resolve(pwd, f)))
    )
}

logDebug(
    `coverage manifest ${process.env.COVERAGE_MANIFEST}: ${include.length} entries`
)

report
    .run()
    .then(() => {
        fs.renameSync(path.join(process.env.COVERAGE_DIR, 'lcov.info'), stash)
        const total = (Number(process.hrtime.bigint() - started) / 1e6).toFixed(0)
        logDebug(
            `coverage report generated in ${total}ms${timings.length ? ` (${timings.join(' ')})` : ''}`
        )
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
