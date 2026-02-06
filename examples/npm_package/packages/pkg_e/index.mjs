/**
 * @fileoverview minimal test program that requires a another workspace project
 * that defines its package using js_library.
 */

import { fileURLToPath } from 'node:url'

import { sandboxAssert as bSandboxAssert } from '@mycorp/pkg-b'
import { sandboxAssert as dSandboxAssert } from '@mycorp/pkg-d'
export { getAcornVersion, toAst, uuid } from '@mycorp/pkg-d'

export async function sandboxAssert() {
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

    // Static import of pkg-b,d
    bSandboxAssert()
    dSandboxAssert()

    // Dynamic import of pkg-b,d
    await import('@mycorp/pkg-b').then(({ sandboxAssert }) => sandboxAssert())
    await import('@mycorp/pkg-d').then(({ sandboxAssert }) => sandboxAssert())

    // Resolve of pkg-d
    const pkgDPath = fileURLToPath(import.meta.resolve('@mycorp/pkg-d'))
    if (!sandboxRe.test(pkgDPath)) {
        throw new Error(`pkg-d not in sandbox: ${pkgDPath}`)
    }
    if (process.platform !== 'win32' && !pkgDPath.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`pkg-d not in runfiles: ${pkgDPath}`)
    }
}

global['pkg_e__mjs'] ??= 0
if (++global['pkg_e__mjs'] > 1) {
    throw new Error('pkg_e index.mjs loaded multiple times')
}
await sandboxAssert()
