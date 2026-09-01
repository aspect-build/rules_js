const assert = require('node:assert')

const meaningOfLife = require('meaning-of-life')

// `meaning-of-life@1.0.0.patch` changes 42 to "forty two" and the custom
// `patch_tool.sh` appends the " (custom patch_tool)" suffix.
assert.strictEqual(meaningOfLife, 'forty two (custom patch_tool)')
