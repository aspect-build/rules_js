/**
 * @fileoverview minimal test program that requires a another workspace project
 * that defines its package using js_library.
 */

import { fileURLToPath } from 'node:url'

import { sandboxAssert as dSandboxAssert } from '@mycorp/pkg-d'
export { getAcornVersion, toAst, uuid } from '@mycorp/pkg-d'

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (
        !/-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/.*\.runfiles\/.*\/index.mjs$/.test(
            __filename
        )
    ) {
        throw new Error(`Not in sandbox runfiles: ${__filename}`)
    }

    dSandboxAssert()
}

sandboxAssert()
