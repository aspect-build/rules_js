import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// The V8->lcov conversion needs the instrumented sources, which only exist in the
// test action (not this _lcov_merger action). So the test action runs this script
// with JS_COVERAGE__GENERATE_ONLY=1 and leaves the report in COVERAGE_DIR; here in
// the merger we just publish it. See aspect-build/rules_js#2901.
const jsCovStash = path.join(process.env.COVERAGE_DIR || '', '_rules_js_report.dat')
if (!process.env.JS_COVERAGE__GENERATE_ONLY) {
    try {
        if (fs.statSync(jsCovStash).size != 0) {
            fs.renameSync(jsCovStash, process.env.COVERAGE_OUTPUT_FILE)
            process.exit(0)
        }
    } catch {}
}

// bazel will create the COVERAGE_OUTPUT_FILE whilst setting up the sandbox.
// therefore, should be doing a file size check rather than presence.
try {
    const stats = fs.statSync(process.env.COVERAGE_OUTPUT_FILE)
    if (stats.size != 0) {
        // early exit here does not affect the outcome of the tests.
        // bazel will only execute _lcov_merger when tests pass.
        process.exit(0)
    }
    // in case file doesn't exist or some other error is thrown, just ignore it.
} catch {}

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

new Report({
    include: include,
    exclude: include.length === 0 ? ['**'] : [],
    reportsDirectory: process.env.COVERAGE_DIR,
    tempDirectory: process.env.COVERAGE_DIR,
    resolve: '',
    src: pwd,
    all: true,
    reporter: ['lcovonly'],
})
    .run()
    .then(() => {
        // In the test action, stash the report in COVERAGE_DIR for the merger to
        // publish; the test action's COVERAGE_OUTPUT_FILE is not the final one.
        fs.renameSync(
            path.join(process.env.COVERAGE_DIR, 'lcov.info'),
            process.env.JS_COVERAGE__GENERATE_ONLY
                ? jsCovStash
                : process.env.COVERAGE_OUTPUT_FILE
        )
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
