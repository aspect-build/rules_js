const packageJson = require('./package.json')
const assert = require('uvu/assert')
const lib = require('@e2e/lib')
assert.is(2 + 2, 4)
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }` + lib.id(),
}
