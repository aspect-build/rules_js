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

// c8's Report asks its `exclude` object three questions: which executed scripts belong
// in the report, which unexecuted files belong in it, and which extensions are
// instrumentable at all. Bazel already answered all three in COVERAGE_MANIFEST.
//
// test-exclude answers them by globbing the whole runfiles tree and minimatching every
// hit against every manifest entry -- and prepGlobPatterns expands each entry into
// several patterns -- which is O(files in runfiles x manifest entries) in each test
// action, charged against the test's own timeout. This replaces it with lookups against
// the set Bazel handed us.
//
// It replaces the object rather than patching methods on it, so a method c8 starts
// calling that we have not implemented fails loudly instead of silently falling back to
// the tree walk. Standing in for, pinned to the version c8 10.1.3 resolves:
// https://github.com/istanbuljs/test-exclude/blob/3a37faa17cc4f0f602a7c1ec23ef0b0fcf44ab37/index.js
class ManifestExclude {
    constructor(root, files, extensions) {
        this.root = root
        this.files = files
        this.extensions = extensions
        this.instrumented = new Set(files.map((f) => path.resolve(root, f)))
        // _includeUncoveredFiles reads this directly and drops any path whose extension
        // is not in it before stat'ing the rest.
        this.extension = [...extensions]
    }

    // index.js#L76. c8 asks this of every executed script, so the original costs manifest
    // size times scripts loaded. extname does not care whether a path is resolved, so
    // reject on extension first and skip the resolve for anything uninstrumentable.
    shouldInstrument(filename) {
        if (!this.extensions.has(path.extname(filename))) return false
        return this.instrumented.has(path.resolve(this.root, filename))
    }

    // index.js#L105. c8 calls this from _includeUncoveredFiles, the `all: true` pass that
    // reports files no test executed. Those are exactly the manifest entries no V8 profile
    // mentioned, so the walk it replaces could only ever have found a subset of them.
    //
    // Entries not on disk must be dropped here rather than left to c8: it stats each
    // returned path without guarding, where a real glob never yields a path that is not
    // there. A manifest entry need not be in this test's runfiles -- a first-party library
    // repackaged by npm_package reaches the manifest at its source path but reaches
    // runfiles only as a copy inside the node_modules store.
    globSync(cwd = this.root) {
        // c8 passes an entry of `src`, and we give it exactly one. Manifest entries are
        // relative to that directory, so another root cannot be answered from the manifest
        // and silently reporting the wrong paths would be worse than failing.
        if (cwd !== this.root) {
            throw new Error(
                `coverage report requested for ${cwd}, but the manifest describes ${this.root}`
            )
        }
        return this.files.filter((f) => fs.existsSync(path.resolve(this.root, f)))
    }

    // index.js#L119. test-exclude pairs glob with globSync the way fs does. Report only
    // calls the sync one today, but implementing one and not the other would leave a
    // silent path back to the tree walk if that changed. Nothing here is async.
    async glob(cwd = this.root) {
        return this.globSync(cwd)
    }
}

// `include`, `exclude`, `extension`, `excludeNodeModules` and `allowExternal` are omitted:
// Report forwards them to the test-exclude instance it builds in its constructor, and we
// replace that instance outright.
const report = new Report({
    reportsDirectory: process.env.COVERAGE_DIR,
    tempDirectory: process.env.COVERAGE_DIR,
    resolve: '',
    src: pwd,
    all: true,
    reporter: ['lcovonly'],
})

report.exclude = new ManifestExclude(pwd, include, extensions)

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
