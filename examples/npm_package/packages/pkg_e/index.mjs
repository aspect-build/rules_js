/**
 * @fileoverview minimal test program that requires a another workspace project
 * that defines its package using js_library.
 */

import { fileURLToPath } from 'node:url'

import { sandboxAssert as dSandboxAssert } from '@mycorp/pkg-d'
export { getAcornVersion, toAst, uuid } from '@mycorp/pkg-d'

export async function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }

    // Static import of pkg-d
    dSandboxAssert()

    // Dynamic import of pkg-d
    await import('@mycorp/pkg-d').then(({ sandboxAssert }) => sandboxAssert())

    // Resolve of pkg-d
    const pkgDPath = fileURLToPath(import.meta.resolve('@mycorp/pkg-d'))
    if (!/-sandbox\/\d+\/execroot\//.test(pkgDPath)) {
        throw new Error(`pkg-d not in sandbox: ${pkgDPath}`)
    }
    if (!pkgDPath.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`pkg-d not in runfiles: ${pkgDPath}`)
    }
}

await sandboxAssert()
