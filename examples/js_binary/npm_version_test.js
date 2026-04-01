const assert = require('assert')
const child_process = require('child_process')
const npmVersion = child_process.execSync('npm --version').toString().trim()
assert.equal(npmVersion, '10.9.4')
