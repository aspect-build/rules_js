import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// Runs in the test action, the only place the V8 data and the instrumented sources are
// both present. coverage.sh.tpl reads back this exact filename; keep them in sync.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.lcov')

const LOG_DEBUG = !!process.env.JS_BINARY__LOG_DEBUG

// Report generation is charged against the test's own timeout, so when something is slow
// this is the only place that says so.
function logDebug(message) {
    if (LOG_DEBUG) {
        console.error(`DEBUG: ${process.env.JS_BINARY__LOG_PREFIX}: ${message}`)
    }
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
// COVERAGE_MANIFEST, so membership is a lookup. c8 would otherwise answer the same
// question by globbing the whole runfiles tree and matching every hit against every
// manifest entry, which is O(files in runfiles x manifest entries) in each test action.
// The three hooks below replace that with the set Bazel already knows.
//
// They are methods of TestExclude, which c8 constructs from the Report options above:
// https://github.com/istanbuljs/test-exclude/blob/3a37faa17cc4f0f602a7c1ec23ef0b0fcf44ab37/index.js
const instrumented = new Set(include.map((f) => path.resolve(pwd, f)))

// Replaces shouldInstrument (index.js#L76), which minimatches the filename against
// every include pattern -- and prepGlobPatterns expands each manifest entry into
// several. c8 asks this of every executed script, so the cost is manifest size times
// scripts loaded, in every test action.
report.exclude.shouldInstrument = function shouldInstrument(filename) {
    if (!extensions.has(path.extname(filename))) return false
    return instrumented.has(path.resolve(pwd, filename))
}

// Replaces globSync (index.js#L105), which walks cwd for files matching the extension
// pattern and filters them through shouldInstrument. c8 calls it from
// _includeUncoveredFiles, the `all: true` pass that reports files no test executed.
// Those files are exactly the manifest entries no V8 profile mentioned, so the walk
// could only ever have found a subset of them.
//
// Non-existent entries must be filtered out here rather than left to c8: it stats each
// returned path without guarding, where the real glob simply never yielded a path that
// was not on disk. A manifest entry need not be in this test's runfiles -- a first-party
// library repackaged by npm_package reaches the manifest at its source path but reaches
// runfiles only as a copy inside the node_modules store.
report.exclude.globSync = function globSync(cwd = pwd) {
    // c8 passes an entry of `src`, and we give it exactly one. Manifest entries are
    // relative to that directory, so another cwd cannot be answered from the manifest
    // and silently reporting the wrong paths would be worse than failing.
    if (cwd !== pwd) {
        throw new Error(
            `coverage report requested for ${cwd}, but the manifest describes ${pwd}`
        )
    }
    return include.filter((f) => fs.existsSync(path.resolve(pwd, f)))
}

// TestExclude pairs glob (index.js#L119) with globSync the way fs does. Report only
// calls the sync one today, so this override is unreachable -- but overriding one and
// not the other would leave a silent path back to the tree walk if that ever changed.
// Nothing here is async, so it just defers to the sync implementation.
report.exclude.glob = async function glob(cwd = pwd) {
    return report.exclude.globSync(cwd)
}

logDebug(
    `coverage manifest ${process.env.COVERAGE_MANIFEST}: ${include.length} entries`
)

report
    .run()
    .then(() => {
        fs.renameSync(path.join(process.env.COVERAGE_DIR, 'lcov.info'), stash)
        const total = (Number(process.hrtime.bigint() - started) / 1e6).toFixed(0)
        logDebug(`coverage report generated in ${total}ms`)
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
