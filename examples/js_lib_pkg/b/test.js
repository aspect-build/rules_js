const { strict: assert } = require('node:assert')
const { test } = require('js_lib_pkg_a')
const { test: test2 } = require('js_lib_pkg_a-alias')
assert.equal(test, test2, 'test')
