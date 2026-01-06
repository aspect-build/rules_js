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

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }

    // Resolve of third-party package 'uuid'
    const uuid_path = require.resolve('uuid')
    if (!/-sandbox\/\d+\/execroot\//.test(uuid_path)) {
        throw new Error(`uuid not in sandbox: ${uuid_path}`)
    }
    if (!uuid_path.includes('/node_modules/.aspect_rules_js/uuid@')) {
        throw new Error(`uuid not in package store: ${uuid_path}`)
    }
    if (!uuid_path.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`uuid not in runfiles: ${uuid_path}`)
    }
}

module.exports = {
    toAst,
    getAcornVersion,
    uuid,
    sandboxAssert,
}

sandboxAssert()
