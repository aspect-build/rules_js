const { Runfiles } = require('@bazel/runfiles')
const { join } = require('node:path')

const runfiles = new Runfiles(process.env)

console.log(
    process.argv.slice(2).map((a) => runfiles.resolve(join('e2e_runfiles', a)))
)
