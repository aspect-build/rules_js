'use strict'

const fs = require('fs')
const path = require('path')

// The _lcov_merger step: publish the report coverage.js generated. See #2901.
// Written by coverage.js in the test action, carried here via COVERAGE_DIR.
const stash = path.join(process.env.COVERAGE_DIR || '', '_rules_js_report.dat')

try {
    if (fs.statSync(stash).size > 0) {
        fs.renameSync(stash, process.env.COVERAGE_OUTPUT_FILE)
    }
    // No stash (generation failed or produced nothing): leave the empty output.
} catch {}
