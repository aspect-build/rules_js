import * as path from 'node:path'
import {
    isNodeModulePath,
    isPackageStorePath,
    isUnderNodeModules,
    resolveSandboxSymlinkTarget,
    friendlyFileSize,
    sandboxRelativeChdir,
} from '../../devserver/js_run_devserver.mjs'

// isNodeModulePath
const isNodeModulePath_true = [
    '/private/var/some/path/node_modules/@babel/core',
    '/private/var/some/path/node_modules/lodash',
]
for (const p of isNodeModulePath_true) {
    if (!isNodeModulePath(p)) {
        console.error(`ERROR: expected ${p} to be a node_modules path`)
        process.exit(1)
    }
}
const isNodeModulePath_false = ['/private/var/some/path/some-file.js']
for (const p of isNodeModulePath_false) {
    if (isNodeModulePath(p)) {
        console.error(`ERROR: expected ${p} to not be a node_modules path`)
        process.exit(1)
    }
}

// isPackageStorePath
const isPackageStorePath_true = [
    'some/path/node_modules/.aspect_rules_js/mycorp-pkg@0.0.0/node_modules/mycorp-pkg',
    'some/path/node_modules/.aspect_rules_js/@mycorp+pkg@0.0.0/node_modules/@mycorp/pkg',
    'node_modules/.aspect_rules_js/next@16.2.1/node_modules/next/dist/bin/next',
]
for (const p of isPackageStorePath_true) {
    if (!isPackageStorePath(p)) {
        console.error(`ERROR: expected ${p} to be a package store path`)
        process.exit(1)
    }
}
const isPackageStorePath_false = [
    'some/path/node_modules/next',
    'some/path/node_modules/@types/node',
    'some/path/some-file.js',
]
for (const p of isPackageStorePath_false) {
    if (isPackageStorePath(p)) {
        console.error(`ERROR: expected ${p} to not be a package store path`)
        process.exit(1)
    }
}

// isUnderNodeModules
const isUnderNodeModules_true = [
    'some/path/node_modules/next',
    'some/path/node_modules/@types/node',
    // .bin entries and files within a package's contents are not package directories, but they are
    // still resolved through node_modules and so must not point outside the sandbox.
    'some/path/node_modules/.bin/next',
    'node_modules/.bin/next',
    'some/path/node_modules/next/dist/bin/next',
    'node_modules/.aspect_rules_js/next@16.2.1/node_modules/next/package.json',
]
for (const p of isUnderNodeModules_true) {
    if (!isUnderNodeModules(p)) {
        console.error(`ERROR: expected ${p} to be under node_modules`)
        process.exit(1)
    }
}
const isUnderNodeModules_false = [
    'some/path/some-file.js',
    'src/app/page.tsx',
    // A directory that merely ends in node_modules is not a node_modules tree.
    'some/path/not_node_modules',
    'node_modules',
]
for (const p of isUnderNodeModules_false) {
    if (isUnderNodeModules(p)) {
        console.error(`ERROR: expected ${p} to not be under node_modules`)
        process.exit(1)
    }
}

// resolveSandboxSymlinkTarget
const SANDBOX = path.join('/tmp', 'js_run_devserver-abc123', '_main')
// `linkPath` is relative to the symlink itself, matching what syncSymlink computes.
const LINK = 'app/node_modules/next'
const LINK_PATH = path.join(
    '..',
    '..',
    '..',
    'node_modules',
    '.aspect_rules_js',
    'next@16.2.1',
    'node_modules',
    'next'
)
const STORE_ENTRY =
    'node_modules/.aspect_rules_js/next@16.2.1/node_modules/next'

// The package store entry is synced, so the link resolves into the sandbox.
{
    const actual = resolveSandboxSymlinkTarget(
        SANDBOX,
        LINK,
        LINK_PATH,
        new Set([STORE_ENTRY])
    )
    const expected = path.join(SANDBOX, STORE_ENTRY)
    if (actual !== expected) {
        console.error(
            `ERROR: expected resolveSandboxSymlinkTarget to return '${expected}' but got '${actual}'`
        )
        process.exit(1)
    }
}

// A file under a synced directory entry also resolves; the directory entry covers it.
{
    const deepLinkPath = path.join(LINK_PATH, 'dist', 'bin')
    const actual = resolveSandboxSymlinkTarget(
        SANDBOX,
        LINK,
        deepLinkPath,
        new Set([STORE_ENTRY])
    )
    const expected = path.join(SANDBOX, STORE_ENTRY, 'dist', 'bin')
    if (actual !== expected) {
        console.error(
            `ERROR: expected resolveSandboxSymlinkTarget to return '${expected}' but got '${actual}'`
        )
        process.exit(1)
    }
}

// Nothing synced for the target, so there is no in-sandbox path to point at.
{
    const actual = resolveSandboxSymlinkTarget(
        SANDBOX,
        LINK,
        LINK_PATH,
        new Set(['app/index.js'])
    )
    if (actual !== undefined) {
        console.error(
            `ERROR: expected resolveSandboxSymlinkTarget to return undefined but got '${actual}'`
        )
        process.exit(1)
    }
}

// A target that escapes the sandbox root is never used.
{
    const actual = resolveSandboxSymlinkTarget(
        SANDBOX,
        LINK,
        path.join('..', '..', '..', '..', '..', 'elsewhere'),
        new Set(['elsewhere'])
    )
    if (actual !== undefined) {
        console.error(
            `ERROR: expected resolveSandboxSymlinkTarget to return undefined for a target outside the sandbox but got '${actual}'`
        )
        process.exit(1)
    }
}

// friendlyFileSize
const friendlyFileSize_cases = new Map()
friendlyFileSize_cases.set(0, '0 B')
friendlyFileSize_cases.set(1, '1 B')
friendlyFileSize_cases.set(100, '100 B')
friendlyFileSize_cases.set(1023, '1023 B')
friendlyFileSize_cases.set(1024, '1.0 KiB')
friendlyFileSize_cases.set(1300, '1.3 KiB')
friendlyFileSize_cases.set(1024 * 1024, '1.0 MiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024, '1.0 GiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024 * 1024, '1.0 TiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024 * 1024 * 1024, '1.0 PiB')
friendlyFileSize_cases.set(
    1024 * 1024 * 1024 * 1024 * 1024 * 1024,
    '1024.0 PiB'
)
for (const [k, v] of friendlyFileSize_cases) {
    const a = friendlyFileSize(k)
    if (a !== v) {
        console.error(
            `Expected friendlyFileSize(${k}) to be '${v}' but got '${a}'`
        )
        process.exit(1)
    }
}

// sandboxRelativeChdir
const sandboxRelativeChdir_cases = new Map()
sandboxRelativeChdir_cases.set(undefined, '')
sandboxRelativeChdir_cases.set('', '')
sandboxRelativeChdir_cases.set('.', '.')
sandboxRelativeChdir_cases.set('foo/bar', 'foo/bar')
// The sandbox has no external/ directory; a repository sits beside the main one
sandboxRelativeChdir_cases.set('external/myrepo', '../myrepo')
sandboxRelativeChdir_cases.set('external/myrepo/foo/bar', '../myrepo/foo/bar')
for (const [k, v] of sandboxRelativeChdir_cases) {
    const a = sandboxRelativeChdir(k)
    if (a !== v) {
        console.error(
            `Expected sandboxRelativeChdir(${k}) to be '${v}' but got '${a}'`
        )
        process.exit(1)
    }
}
