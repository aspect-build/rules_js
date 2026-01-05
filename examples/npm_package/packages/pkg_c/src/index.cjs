const pkgC = require('./pkg-c.json')

function sandboxAssert() {
    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Use of npm_package() copies files into the npm package store.
    if (!__filename.includes('/node_modules/.aspect_rules_js/')) {
        throw new Error(`Not in package store: ${__filename}`)
    }
}

sandboxAssert()

module.exports.name = pkgC.name
module.exports.sandboxAssert = sandboxAssert
