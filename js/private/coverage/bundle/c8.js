import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

// Runs in the test action, the only place the V8 data and instrumented sources are
// both present. coverage.sh.tpl reads back this exact filename; keep them in sync.
const stash = path.join(process.env.COVERAGE_DIR, '_rules_js_report.lcov')

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
