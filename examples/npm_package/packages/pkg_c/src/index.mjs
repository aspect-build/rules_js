import { fileURLToPath } from 'node:url'
import pkgC from './pkg-c.json' assert { type: 'json' }

export default pkgC

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    if (
        !/-sandbox\/\d+\/execroot\/_main\/bazel-out\/.*\/bin\/node_modules\/\.aspect_rules_js\/[^\/]+\/node_modules\/@mycorp\/pkg-c\d\/index\.mjs$/.test(
            __filename
        )
    ) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // TODO: https://github.com/aspect-build/rules_js/issues/362
    // if (
    //     !/\/bazel-out\/[^/]+\/bin\/.*\.runfiles\/.*\/index.mjs$/.test(
    //         __filename
    //     )
    // ) {
    //     throw new Error(`Not in runfiles: ${__filename}`)
    // }
}

sandboxAssert()
