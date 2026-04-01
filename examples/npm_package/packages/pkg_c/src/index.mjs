import { fileURLToPath } from 'node:url'
import pkgC from './pkg-c.json' with { type: 'json' }

export default pkgC

export function sandboxAssert() {
    const __filename = fileURLToPath(import.meta.url)

    const sandboxRe = process.platform === 'win32'
        ? /[/\\]execroot[/\\]/
        : /-sandbox\/\d+\/execroot\//;
    if (!sandboxRe.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Use of npm_package() copies files into the npm package store.
    if (!/[/\\]node_modules[/\\]\.aspect_rules_js[/\\]/.test(__filename)) {
        throw new Error(`Not in package store: ${__filename}`)
    }

    // When running under test, files should be in runfiles.
    // This package may also be used as a run_binary(tool) and not in a test.
    // On Windows, Node.js resolves junctions to their real path so __filename
    // won't start with RUNFILES_DIR.
    if (process.env.TEST_WORKSPACE && process.platform !== 'win32') {
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
