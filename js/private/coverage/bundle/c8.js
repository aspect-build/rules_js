import { Report } from 'c8'
import fs from 'fs'
import os from 'os'
import path from 'path'
import { fileURLToPath, pathToFileURL } from 'url'

// Runs in the test action, the only place the V8 data and the instrumented sources are
// both present. coverage.sh.tpl reads back this exact filename; keep them in sync.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.lcov')

const debug = !!process.env.JS_BINARY__LOG_DEBUG
const timings = []

// Report generation is charged against the test's own timeout, so when something is slow
// this is the only place that says which part.
function logDebug(message) {
    if (debug) {
        console.error(`DEBUG: ${process.env.JS_BINARY__LOG_PREFIX}: ${message}`)
    }
}

function timed(label, fn) {
    if (!debug) return fn()
    const start = process.hrtime.bigint()
    const value = fn()
    timings.push(
        `${label}=${(Number(process.hrtime.bigint() - start) / 1e6).toFixed(0)}ms`
    )
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

// Bazel already computed the exact set of instrumented files and handed it to us in
// COVERAGE_MANIFEST. Left to itself c8 rediscovers that set by globbing the whole runfiles
// tree and minimatching every hit against every manifest entry, which is
// O(files in runfiles x manifest entries) in each test action. Rather than override the
// discovery, the code below hands c8 only the coverage data that belongs in the report and
// turns the discovery off (`all: false`), so nothing has to be patched.
const instrumented = new Set(include.map((f) => path.resolve(pwd, f)))

// Must not be inside COVERAGE_DIR: c8 reads every file in the directory it is given, and
// the reporter must not leave a profile of its own in COVERAGE_DIR either.
const scratch = fs.mkdtempSync(
    path.join(process.env.TEST_TMPDIR || os.tmpdir(), 'rules_js_coverage-')
)

// The profiles node and coverage.cjs wrote, restricted to the instrumented set. c8 accepts
// any file that parses as `{result: [...]}`, so a prepared directory is ordinary input
// rather than a patch, and everything downstream -- cross-process merging, the
// source-map cache, v8-to-istanbul, the lcov writer -- stays c8's.
const covered = new Set()
const kept = timed('filter_profiles', () => {
    let n = 0
    for (const entry of fs.readdirSync(process.env.COVERAGE_DIR)) {
        let profile
        try {
            profile = JSON.parse(
                fs.readFileSync(path.join(process.env.COVERAGE_DIR, entry), 'utf8')
            )
        } catch {
            // Not a V8 profile. The previous run's lcov stash lives in here too.
            continue
        }
        if (!profile || !Array.isArray(profile.result)) continue
        const result = profile.result.filter((script) => {
            if (typeof script.url !== 'string' || !script.url.startsWith('file://')) {
                return false
            }
            const file = fileURLToPath(script.url)
            if (!instrumented.has(file)) return false
            covered.add(file)
            return true
        })
        // Spread so `source-map-cache` and `timestamp` carry through untouched: the
        // transpiled test's line mapping depends on them.
        fs.writeFileSync(
            path.join(scratch, entry),
            JSON.stringify({ ...profile, result })
        )
        n += result.length
    }
    return n
})

// What `all: true` used to produce by globbing. The files no test executed are exactly the
// manifest entries no profile mentioned, so they can be synthesized directly. Entries that
// are not on disk must be skipped: a manifest entry need not be in this test's runfiles --
// a `.d.ts` in a js_library's srcs reaches the manifest but is routed to types, not runfiles.
const uncovered = timed('uncovered_scan', () => {
    const result = []
    for (const f of include) {
        const file = path.resolve(pwd, f)
        if (covered.has(file)) continue
        const stat = fs.statSync(file, { throwIfNoEntry: false })
        if (!stat) continue
        result.push({
            scriptId: 0,
            url: pathToFileURL(file).href,
            functions: [
                {
                    functionName: '(empty-report)',
                    ranges: [{ startOffset: 0, endOffset: stat.size, count: 0 }],
                    isBlockCoverage: true,
                },
            ],
        })
    }
    fs.writeFileSync(
        path.join(scratch, 'coverage-uncovered.json'),
        JSON.stringify({ result })
    )
    return result.length
})

const report = new Report({
    tempDirectory: scratch,
    reportsDirectory: process.env.COVERAGE_DIR,
    resolve: '',
    extension: [...extensions],
    // Bazel already decided what is instrumented, so neither of c8's own filters may
    // narrow it further: `exclude` would otherwise default to globs that drop `**/test/**`
    // and `**/*.d.ts`, and node_modules is where a first-party library linked with
    // npm_link_package lives.
    exclude: [],
    excludeNodeModules: false,
    // No glob: `all` is the only caller of the directory walk this replaces.
    all: false,
    reporter: ['lcovonly'],
})

logDebug(
    `coverage manifest ${process.env.COVERAGE_MANIFEST}: ${include.length} entries, ${kept} covered scripts, ${uncovered} uncovered`
)

report
    .run()
    .then(() => {
        fs.renameSync(path.join(process.env.COVERAGE_DIR, 'lcov.info'), stash)
        fs.rmSync(scratch, { recursive: true, force: true })
        const total = (Number(process.hrtime.bigint() - started) / 1e6).toFixed(0)
        logDebug(
            `coverage report generated in ${total}ms${timings.length ? ` (${timings.join(' ')})` : ''}`
        )
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
