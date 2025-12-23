/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
import { fileURLToPath } from 'node:url'
import * as acorn from 'acorn'
export { v4 as uuid } from 'uuid'

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }
}

export function toAst(program) {
    return JSON.stringify(acorn.parse(program, { ecmaVersion: 2020 })) + '\n'
}

export function getAcornVersion() {
    return acorn.version
}

sandboxAssert()
