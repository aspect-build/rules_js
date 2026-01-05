/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
import { fileURLToPath } from 'node:url'
import * as acorn from 'acorn'

export { acorn }
export { v4 as uuid } from 'uuid'

export function toAst(program) {
    return JSON.stringify(acorn.parse(program, { ecmaVersion: 2020 })) + '\n'
}

export function getAcornVersion() {
    return acorn.version
}

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Use of npm_package() copies files into the npm package store.
    if (!__filename.includes('/node_modules/.aspect_rules_js/')) {
        throw new Error(`Not in package store: ${__filename}`)
    }
}

sandboxAssert()
