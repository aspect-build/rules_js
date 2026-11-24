const assert = require('node:assert/strict')

const entry = './node_modules/.aspect_rules_js/lib@0.0.0/node_modules/lib'
assert.equal(require.resolve(entry), require.resolve('../index.js'))
