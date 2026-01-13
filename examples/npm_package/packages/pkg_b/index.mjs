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

    // When running under test, files should be in runfiles.
    // This package may also be used as a run_binary(tool) and not in a test.
    if (process.env.TEST_WORKSPACE) {
        if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
            throw new Error(`Not in runfiles: ${__filename}`)
        }
    }

    // Resolve of third-party package 'uuid'
    const uuid_path = fileURLToPath(import.meta.resolve('uuid'))
    if (!/-sandbox\/\d+\/execroot\//.test(uuid_path)) {
        throw new Error(`uuid not in sandbox: ${uuid_path}`)
    }
    if (!uuid_path.includes('/node_modules/.aspect_rules_js/uuid@')) {
        throw new Error(`uuid not in package store: ${uuid_path}`)
    }
    if (process.env.TEST_WORKSPACE) {
        if (!uuid_path.startsWith(process.env.RUNFILES_DIR)) {
            throw new Error(
                `uuid not in runfiles while __filename is: ${uuid_path}`
            )
        }
    }
}

global['pkg_b__mjs'] ??= 0
if (++global['pkg_b__mjs'] > 1) {
    throw new Error('pkg_b index.mjs loaded multiple times')
}
sandboxAssert()
