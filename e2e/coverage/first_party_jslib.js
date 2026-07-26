const assert = require('node:assert')
const lib = require('@repro/jslib')

assert.strictEqual(lib.covered(), 'covered')
