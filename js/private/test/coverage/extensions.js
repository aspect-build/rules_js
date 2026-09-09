// Requires only extCovered, so the report has both an executed and an unexecuted
// function to assert on.
const { extCovered } = require('./extensions/lib.js')

extCovered()

// The extensions filter has to be asserted here rather than in the merger. COVERAGE_MANIFEST
// exists only in the test action, which is the one place the filter is observable.
if (process.env.COVERAGE_MANIFEST) {
    const fs = require('node:fs')
    const entries = fs
        .readFileSync(process.env.COVERAGE_MANIFEST, 'utf8')
        .split('\n')
        .filter((f) => f !== '')

    const unexpected = entries.filter((f) => !/\.[cm]?[jt]sx?$/.test(f))
    if (unexpected.length) {
        console.error(
            `js_library instrumented sources that are not JS or TS: ${unexpected.join(', ')}`
        )
        process.exit(1)
    }
    if (!entries.some((f) => f.endsWith('extensions/lib.js'))) {
        console.error(
            `expected the js_library source in the manifest, got: ${entries.join(', ')}`
        )
        process.exit(1)
    }
}
