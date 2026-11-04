// Runs in both the root process of the opt_out test and the child it spawns.
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
    // Outside of `bazel coverage` the launcher sets nothing, so the action is unchanged.
    assert.ok(
        !process.env.JS_BINARY__NO_COVERAGE,
        'expected JS_BINARY__NO_COVERAGE to be set only under coverage'
    )
}
