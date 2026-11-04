// Runs in both processes of the opt_out test and as the entry point of opt_out_bin.
const assert = require('node:assert')

if (process.env.COVERAGE_DIR) {
    assert.strictEqual(
        process.env.JS_BINARY__NO_COVERAGE,
        '1',
        'expected collect_coverage = False to set JS_BINARY__NO_COVERAGE'
    )
    assert.ok(
        !process.env.NODE_V8_COVERAGE,
        `expected no v8 coverage session, got NODE_V8_COVERAGE '${process.env.NODE_V8_COVERAGE}'`
    )
} else {
    assert.ok(
        !process.env.JS_BINARY__NO_COVERAGE,
        'expected JS_BINARY__NO_COVERAGE to be set only under coverage'
    )
}
