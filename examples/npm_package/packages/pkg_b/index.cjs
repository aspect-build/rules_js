/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
const acorn = require('acorn')
const { v4: uuid } = require('uuid')

function toAst(program) {
    return JSON.stringify(acorn.parse(program, { ecmaVersion: 2020 })) + '\n'
}

function getAcornVersion() {
    return acorn.version
}

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

module.exports = {
    toAst,
    getAcornVersion,
    uuid,
    sandboxAssert,
}
