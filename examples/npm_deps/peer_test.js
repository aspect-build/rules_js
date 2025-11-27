const cjs = require('@rollup/plugin-commonjs/package.json')
const assert = require('assert')
const react = require('react')
const mobx = require('mobx-react/package.json')
assert.equal(react.version, '17.0.2')
assert.equal(mobx.version, '7.3.0')
assert.equal(cjs.version, '21.1.0')

// Ensure the main package with peer dependencies works too
require('@rollup/plugin-commonjs')
