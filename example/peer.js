const cjs = require('@rollup/plugin-commonjs/package.json')
const rollup = require('rollup')
const assert = require('assert')

assert.equal(cjs.version, '21.1.0')
assert.equal(rollup.VERSION, '2.70.2')
