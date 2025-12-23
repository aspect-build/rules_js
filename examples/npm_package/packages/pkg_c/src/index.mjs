import { fileURLToPath } from 'node:url'
import pkgC from './pkg-c.json' assert { type: 'json' }

export default pkgC

export function sandboxAssert() {
    // TODO: https://github.com/aspect-build/rules_js/issues/362
    // const __filename = fileURLToPath(import.meta.url)
    //
    // if (
    //     !/-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/.*\.runfiles\/.*\/index.mjs$/.test(
    //         __filename
    //     )
    // ) {
    //     throw new Error(`Not in sandbox: ${__filename}`)
    // }
}

sandboxAssert()
