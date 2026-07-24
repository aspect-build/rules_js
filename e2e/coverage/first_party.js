const assert = require('node:assert')
// Import first-party code by package name so it resolves through the
// .aspect_rules_js store (realpath outside the test's runfiles src root).
const lib = require('@repro/lib')

assert.strictEqual(lib.covered(), 'covered')
