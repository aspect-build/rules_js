import { fileURLToPath } from 'node:url'
import pkgC from './pkg-c.json' with { type: 'json' }

export default pkgC

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
}

global['pkg_c__mjs'] ??= 0
if (++global['pkg_c__mjs'] > 1) {
    throw new Error('pkg_c index.mjs loaded multiple times')
}
sandboxAssert()
