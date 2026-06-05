import { readFileSync } from 'fs'

// The version of the @pnpm repo is resolved from `pnpm_version_from = "//:package.json"`
// on the root module tag, and must match the package.json `packageManager` field.
// It takes priority over both the version requested by the non-root module
// `other_module` and the default version registered by rules_js itself.
// See https://github.com/aspect-build/rules_js/pull/2349#discussion_r3362093839
const packageManager = JSON.parse(
    readFileSync('package.json', 'utf8')
).packageManager
const expected = packageManager.split('@')[1].split('+')[0]
const pnpmVersion = readFileSync('pnpm_version.txt', 'utf8').trim()

if (pnpmVersion !== expected) {
    throw new Error(
        `Incorrect @pnpm version: got ${pnpmVersion}, expected ${expected} from package.json#packageManager`
    )
}

// The root module may register additional pnpm repos with their own pinned version.
const otherPnpmVersion = readFileSync('other_pnpm_version.txt', 'utf8').trim()

if (otherPnpmVersion !== '9.15.9') {
    throw new Error(
        `Incorrect @other_pnpm version: got ${otherPnpmVersion}, expected 9.15.9`
    )
}

// @pnpm was configured with include_npm via a separate, version-less tag, so the
// bundled npm must be runnable. `pnpm exec npm --version` (captured above) only
// produces a version string if npm is on PATH; otherwise the include_npm request
// was dropped because the selected version came from a different tag.
const npmVersion = readFileSync('pnpm_npm_version.txt', 'utf8').trim()

if (!/^\d+\.\d+\.\d+/.test(npmVersion)) {
    throw new Error(`Expected a bundled npm version, got: ${npmVersion}`)
}
