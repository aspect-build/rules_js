const assert = require('node:assert')
const lib = require('./lib.js')

assert.strictEqual(lib.covered(), 'covered')
