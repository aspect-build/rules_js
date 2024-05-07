/**
 * @fileoverview minimal test program that requires third-party packages from npm
 */
const acorn = require('acorn')

function getAcornVersion() {
    return acorn.version
}

function getUuidVersion() {
    return require('uuid/package.json').version
}

module.exports = {
    getAcornVersion,
    getUuidVersion,
}
