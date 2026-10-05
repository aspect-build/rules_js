const assert = require('node:assert/strict')
const fs = require('node:fs')

assert.equal(
    fs.readFileSync('no_runfiles_output.txt', 'utf8'),
    'generated in target configuration'
)
