const assert = require('node:assert')

// Only the root process reports: coverage.cjs deletes this once it has taken it, and the
// child's own launcher.cjs run must not hand it back -- it finds NODE_V8_COVERAGE already
// set, which is how it knows it is not the first node in the tree.
assert.strictEqual(process.env.JS_BINARY__COVERAGE_REPORT, undefined)

// ...and this proves the deletion happened rather than the variable simply never having
// been set: the depth counter grows once per bootstrap, so a value longer than one
// character means this really is a nested js_binary node process.
assert.ok(
    process.env.JS_BINARY__NODE_PATCHES_DEPTH.length > 1,
    `expected a nested bootstrap, got depth '${process.env.JS_BINARY__NODE_PATCHES_DEPTH}'`
)

// Inherited from the process that started this one, so V8 has been recording since this
// process started and no second re-exec was needed to arrange it.
assert.ok(process.env.NODE_V8_COVERAGE, 'NODE_V8_COVERAGE was not inherited')

if (true) {
    childCovered()
} else {
    childUncovered()
}

function childCovered() {
    console.log('child covered')
}

function childUncovered() {
    console.log('child uncovered')
}
