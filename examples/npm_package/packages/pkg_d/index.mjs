/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
import { fileURLToPath } from 'node:url'
import * as acorn from 'acorn'
export { v4 as uuid } from 'uuid'

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    const sandboxRe = process.platform === 'win32'
        ? /[/\\]execroot[/\\]/
        : /-sandbox\/\d+\/execroot\//;
    if (!sandboxRe.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    // On Windows, Node.js resolves junctions to their real path so __filename
    // won't start with RUNFILES_DIR.
    if (process.platform !== 'win32' && !__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }

    // Resolve of third-party package 'uuid'
    const uuid_path = fileURLToPath(import.meta.resolve('uuid'))
    if (!sandboxRe.test(uuid_path)) {
        throw new Error(`uuid not in sandbox: ${uuid_path}`)
    }
    if (!/[/\\]node_modules[/\\]\.aspect_rules_js[/\\]uuid@/.test(uuid_path)) {
        throw new Error(`uuid not in package store: ${uuid_path}`)
    }
    if (process.platform !== 'win32' && !uuid_path.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`uuid not in runfiles: ${uuid_path}`)
    }
}

export function toAst(program) {
    return JSON.stringify(acorn.parse(program, { ecmaVersion: 2020 })) + '\n'
}

export function getAcornVersion() {
    return acorn.version
}

global['pkg_d__mjs'] ??= 0
if (++global['pkg_d__mjs'] > 1) {
    throw new Error('pkg_d index.mjs loaded multiple times')
}
sandboxAssert()
