import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// Runs in the test action, the only place the V8 data and the instrumented sources are
// both present. coverage.sh.tpl reads back this exact filename; keep them in sync.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.lcov')

const LOG_DEBUG = !!process.env.JS_BINARY__LOG_DEBUG

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

// We provide our own implementation of the TestExclude class from here:
// https://github.com/istanbuljs/test-exclude/blob/3a37faa17cc4f0f602a7c1ec23ef0b0fcf44ab37/index.js
// The upstream TestExclude is inefficient for our use case, because it globs the whole
// runfiles tree and matches every result individually against every entry in the coverage
// manifest. This is O(number of runfiles * number of coverage manifest entries), or quadratic
// in the number of runfiles if you assume that those two quantities are proportional to each
// other. Our implementation is careful to avoid this quadratic scaling.
//
// We do not implement every method from the original class, only the ones that Report calls.
// If Report changes then this may break, but it should fail in a loud way that we can address.
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

    shouldInstrument(filename) {
        if (!this.extensions.has(path.extname(filename))) return false
        return this.instrumented.has(path.resolve(this.root, filename))
    }

    globSync(cwd = this.root) {
        // The only directory we know about is this.root, so if we are asked about a different
        // one then we should return an error rather than a wrong answer.
        if (cwd !== this.root) {
            throw new Error(
                `coverage report requested for ${cwd}, but the manifest describes ${this.root}`
            )
        }
        return this.files.filter((f) => fs.existsSync(path.resolve(this.root, f)))
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
