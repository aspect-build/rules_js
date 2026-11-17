const assert = require('node:assert')

const meaningOfLife = require('meaning-of-life')

// `meaning-of-life@1.0.0.patch` changes 42 to "forty two"; with no `patch_tool`
// it was applied by Bazel's native patcher, not a `patch` from PATH.
assert.strictEqual(meaningOfLife, 'forty two')
