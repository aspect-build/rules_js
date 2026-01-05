import { fileURLToPath } from 'node:url'
import pkgC from './pkg-c.json' assert { type: 'json' }

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
}

sandboxAssert()
