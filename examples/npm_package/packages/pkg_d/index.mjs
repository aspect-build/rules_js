/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
import * as acorn from 'acorn'
import { fileURLToPath } from 'node:url'
export { v4 as uuid } from 'uuid'

export function toAst(program) {
    return JSON.stringify(acorn.parse(program, { ecmaVersion: 2020 })) + '\n'
}

export function getAcornVersion() {
    return acorn.version
}

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (
        !/-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/.*\.runfiles\/.*\/index.mjs$/.test(
            __filename
        )
    ) {
        throw new Error(`Not in sandbox runfiles: ${__filename}`)
    }
}

sandboxAssert()
