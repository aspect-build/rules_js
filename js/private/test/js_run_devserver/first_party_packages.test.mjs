import fs from 'node:fs'
import path from 'node:path'

import { findSandboxRoot, isInside, realpath } from './sandbox_test_utils.mjs'

// @image-test/d is a first-party package that depends on the first-party package @image-test/a.
// Both are linked into the package store as `@0.0.0` entries that point at their source directories,
// which are synced into the sandbox.
describe(`first-party packages (package_store_mode = "${process.env.PACKAGE_STORE_MODE}") >`, () => {
    const sandboxRoot = findSandboxRoot()
    const workspaceRoot = path.join(
        sandboxRoot,
        process.env.JS_BINARY__WORKSPACE
    )
    const store = path.join(workspaceRoot, 'node_modules/.aspect_rules_js')
    const aSource = path.join(workspaceRoot, 'js/private/test/image-fixture-a')
    const aStoreEntry = path.join(
        store,
        '@image-test+a@0.0.0/node_modules/@image-test/a'
    )
    // The link to its dependency @image-test/a inside @image-test/d's store entry
    const aFromD = path.join(
        store,
        '@image-test+d@0.0.0/node_modules/@image-test/a'
    )

    it('resolves a dependency of a first-party package to the same real path as the package itself', () => {
        // Two real paths for one package means two module instances, which breaks singletons and
        // instanceof. This depends on the dependency link being synced after the store entry it
        // points at; syncing them concurrently resolves it to bazel-out instead most of the time.
        const real = realpath(aFromD)

        expect(real).toBe(realpath(aSource))
        expect(isInside(sandboxRoot, real)).toBe(true)
    })

    it('links the store entry to its synced source directory rather than copying it', () => {
        // A copy would not see files removed from the source, leaving them resolvable.
        expect(fs.lstatSync(aStoreEntry).isSymbolicLink()).toBe(true)
        expect(realpath(aStoreEntry)).toBe(realpath(aSource))
    })
})
