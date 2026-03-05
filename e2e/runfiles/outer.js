const { Runfiles } = require('@bazel/runfiles')
const { execFileSync } = require('child_process')

// Verify RUNFILES_DIR is set in this (outer) process
const runfiles = new Runfiles(process.env)

// Locate the inner js_binary via runfiles and exec it, passing args through.
// The inner binary also uses @bazel/runfiles, so this tests that RUNFILES_DIR
// set by the outer process is inherited and usable by the inner process.
const innerBinary = runfiles.resolve('e2e_runfiles/test_binary_/test_binary')

const result = execFileSync(innerBinary, process.argv.slice(2), {
    encoding: 'utf8',
})
process.stdout.write(result)
