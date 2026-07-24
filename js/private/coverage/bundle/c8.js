import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// Convert the V8 coverage data to lcov here in the test action, where the data
// (NODE_V8_COVERAGE), instrumented sources, and V8 source URLs are all present.
// A split post-processing action (--experimental_split_coverage_postprocessing,
// implied by remote execution) has none of those, so it cannot. See #2901:
// https://github.com/aspect-build/rules_js/issues/2901.
// Handed off to the _lcov_merger action's publish.js via COVERAGE_DIR.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.dat')

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
        fs.renameSync(path.join(process.env.COVERAGE_DIR, 'lcov.info'), stash)
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
