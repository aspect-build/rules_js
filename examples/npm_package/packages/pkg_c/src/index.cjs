const pkgC = require('./pkg-c.json')

function sandboxAssert() {
    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Use of npm_package() copies files into the npm package store.
    if (!__filename.includes('/node_modules/.aspect_rules_js/')) {
        throw new Error(`Not in package store: ${__filename}`)
    }

    // When running under test, files should be in runfiles.
    // This package may also be used as a run_binary(tool) and not in a test.
    if (process.env.TEST_WORKSPACE) {
        if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
            throw new Error(`Not in runfiles: ${__filename}`)
        }
    }
}

global['pkg_c__cjs'] ??= 0
if (++global['pkg_c__cjs'] > 1) {
    throw new Error('pkg_c index.cjs loaded multiple times')
}
sandboxAssert()

module.exports.name = pkgC.name
module.exports.sandboxAssert = sandboxAssert
