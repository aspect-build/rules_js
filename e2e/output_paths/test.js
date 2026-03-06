const { Runfiles } = require('@bazel/runfiles')

const runfiles = new Runfiles(process.env)
const path = runfiles.resolve('e2e_output_paths/test.js')
if (!path) throw new Error('failed to resolve test.js via runfiles')

const { readFileSync } = require('fs')
const contentsViaRunfiles = readFileSync(path, 'utf8')
const contentsViaDirname = readFileSync(__filename, 'utf8')
if (contentsViaRunfiles !== contentsViaDirname)
    throw new Error(
        `resolved path ${path} does not match __filename ${__filename}`
    )
