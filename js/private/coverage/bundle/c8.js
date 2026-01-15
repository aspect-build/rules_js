import { Report } from 'c8'
import fs from 'fs'
import path from 'path'

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

// When --experimental_split_coverage_postprocessing is enabled, Bazel runs
// coverage post-processing as a separate action. The COVERAGE_DIR may have been
// created by a previous action with restrictive permissions. Ensure we can write
// to it by making the directory writable.
try {
    const coverageDir = process.env.COVERAGE_DIR
    if (coverageDir) {
        const stats = fs.statSync(coverageDir, { throwIfNoEntry: false })
        // Check if directory exists and is not writable by owner
        if (stats && (stats.mode & 0o200) === 0) {
            fs.chmodSync(coverageDir, stats.mode | 0o200)
        }
    }
} catch {
    // Ignore errors - if we can't fix permissions, the write will fail with
    // a more descriptive error message below
}

const include = fs
    .readFileSync(process.env.COVERAGE_MANIFEST)
    .toString('utf8')
    .split('\n')
    .filter((f) => f != '')

// TODO: can or should we instrument files from other repositories as well?
// if so then the path.join call below will yield invalid paths since files will have external/wksp as their prefix.
const pwd = path.join(process.env.RUNFILES, process.env.TEST_WORKSPACE)
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
        fs.renameSync(
            path.join(process.env.COVERAGE_DIR, 'lcov.info'),
            process.env.COVERAGE_OUTPUT_FILE
        )
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
