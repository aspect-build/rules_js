import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import {
    chmodSync,
    mkdtempSync,
    mkdirSync,
    readFileSync,
    renameSync,
    rmSync,
    symlinkSync,
    writeFileSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'

import { createIntegrityManifest, verifyProject } from './pnp_verify.mjs'

function hash(content) {
    return createHash('sha512').update(content).digest('hex')
}

function makeProject() {
    const root = mkdtempSync(join(tmpdir(), 'rules-js-pnp-'))
    const archive = Buffer.from('deterministic archive bytes')
    const archiveName = 'pkg-npm-1.0.0-test.zip'
    mkdirSync(join(root, '.yarn/cache'), { recursive: true })
    writeFileSync(join(root, '.yarn/cache', archiveName), archive)
    writeFileSync(
        join(root, '.yarnrc.yml'),
        'nodeLinker: pnp\npnpEnableInlining: false\n'
    )
    writeFileSync(
        join(root, 'yarn.lock'),
        `__metadata:\n  version: 10\n  cacheKey: 10c0\n\n"pkg@npm:1.0.0":\n  version: 1.0.0\n  resolution: "pkg@npm:1.0.0"\n  checksum: 10c0/${hash(
            archive
        )}\n  languageName: node\n  linkType: hard\n`
    )
    writeFileSync(
        join(root, '.pnp.data.json'),
        JSON.stringify(
            {
                dependencyTreeRoots: [],
                enableTopLevelFallback: false,
                fallbackExclusionList: [],
                fallbackPool: [],
                packageRegistryData: [
                    [
                        'pkg',
                        [
                            [
                                'npm:1.0.0',
                                {
                                    linkType: 'HARD',
                                    packageDependencies: [['pkg', 'npm:1.0.0']],
                                    packageLocation: `./.yarn/cache/${archiveName}/node_modules/pkg/`,
                                },
                            ],
                        ],
                    ],
                ],
            },
            null,
            2
        )
    )
    // Yarn returns null from resolveVirtual for ordinary, non-virtual paths.
    writeFileSync(
        join(root, '.pnp.cjs'),
        `const path = require('path'); path.resolve(__dirname, ".pnp.data.json"); module.exports = {resolveVirtual: () => null};\n`
    )
    writeFileSync(
        join(root, '.pnp.integrity.json'),
        `${JSON.stringify(createIntegrityManifest(root), null, 2)}\n`
    )
    return { archiveName, root }
}

function makeUnpluggedProject() {
    const project = makeProject()
    const dataPath = join(project.root, '.pnp.data.json')
    const data = JSON.parse(readFileSync(dataPath, 'utf8'))
    data.packageRegistryData[0][1][0][1].packageLocation =
        './.yarn/unplugged/pkg-npm-1.0.0/node_modules/pkg/'
    mkdirSync(
        join(project.root, '.yarn/unplugged/pkg-npm-1.0.0/node_modules/pkg'),
        { recursive: true }
    )
    writeFileSync(
        join(
            project.root,
            '.yarn/unplugged/pkg-npm-1.0.0/node_modules/pkg/index.js'
        ),
        'module.exports = true\n'
    )
    writeFileSync(dataPath, JSON.stringify(data, null, 2))
    writeFileSync(
        join(project.root, '.pnp.integrity.json'),
        `${JSON.stringify(createIntegrityManifest(project.root), null, 2)}\n`
    )
    return project
}

test('accepts integrity-bound resolver, graph, config, lock, and cache inputs', () => {
    const { root } = makeProject()
    try {
        assert.deepEqual(verifyProject(root), [])
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a corrupted cache archive against both integrity sources', () => {
    const { archiveName, root } = makeProject()
    try {
        writeFileSync(join(root, '.yarn/cache', archiveName), 'corrupted')
        const errors = verifyProject(root)
        assert(
            errors.some((error) =>
                error.startsWith(
                    `.yarn/cache/${archiveName}: integrity mismatch`
                )
            )
        )
        assert(
            errors.some((error) =>
                error.startsWith('pkg@npm:1.0.0: yarn.lock checksum mismatch')
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a manifest-bound cache archive absent from the PnP graph', () => {
    const { root } = makeProject()
    try {
        writeFileSync(
            join(root, '.yarn/cache/foreign.zip'),
            'foreign archive\n'
        )
        writeFileSync(
            join(root, '.pnp.integrity.json'),
            `${JSON.stringify(createIntegrityManifest(root), null, 2)}\n`
        )
        const errors = verifyProject(root)
        assert(
            errors.includes(
                '.yarn/cache/foreign.zip: integrity-bound cache archive is neither referenced by .pnp.data.json nor the unique lock-backed source for an active unplugged package'
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('accepts the unique lock-backed cache source for an unplugged package', () => {
    const { root } = makeUnpluggedProject()
    try {
        assert.deepEqual(verifyProject(root), [])
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a duplicate lock-backed cache source for an unplugged package', () => {
    const { archiveName, root } = makeUnpluggedProject()
    try {
        const archive = readFileSync(join(root, '.yarn/cache', archiveName))
        writeFileSync(join(root, '.yarn/cache/duplicate.zip'), archive)
        writeFileSync(
            join(root, '.pnp.integrity.json'),
            `${JSON.stringify(createIntegrityManifest(root), null, 2)}\n`
        )
        const errors = verifyProject(root)
        assert(
            errors.some((error) =>
                error.includes(
                    'neither referenced by .pnp.data.json nor the unique lock-backed source for an active unplugged package'
                )
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a malformed present yarn.lock checksum after integrity refresh', () => {
    const { root } = makeProject()
    try {
        const lockPath = join(root, 'yarn.lock')
        writeFileSync(
            lockPath,
            readFileSync(lockPath, 'utf8').replace(
                /checksum: 10c0\/[0-9a-f]{128}/,
                'checksum: 10c0/nothex'
            )
        )
        writeFileSync(
            join(root, '.pnp.integrity.json'),
            `${JSON.stringify(createIntegrityManifest(root), null, 2)}\n`
        )
        const errors = verifyProject(root)
        assert(
            errors.includes(
                'pkg@npm:1.0.0: yarn.lock checksum must be an optional lowercase cache-key prefix and 128 lowercase hexadecimal characters, got 10c0/nothex'
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a mutated executable resolver before loading it', () => {
    const { root } = makeProject()
    try {
        writeFileSync(
            join(root, '.pnp.cjs'),
            'throw new Error("must not execute")\n'
        )
        const errors = verifyProject(root)
        assert(
            errors.some((error) =>
                error.startsWith('.pnp.cjs: integrity mismatch')
            )
        )
        assert(!errors.some((error) => error.includes('must not execute')))
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a mutated resolution graph before loading the resolver', () => {
    const { root } = makeProject()
    try {
        writeFileSync(join(root, '.pnp.data.json'), '{}\n')
        const errors = verifyProject(root)
        assert(
            errors.some((error) =>
                error.startsWith('.pnp.data.json: integrity mismatch')
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('binds executable mode', () => {
    const { root } = makeProject()
    try {
        chmodSync(join(root, '.pnp.cjs'), 0o755)
        const errors = verifyProject(root)
        assert(
            errors.some((error) =>
                error.startsWith('.pnp.cjs: executable mode mismatch')
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects backslash and noncanonical integrity paths', () => {
    const { root } = makeProject()
    try {
        const manifestPath = join(root, '.pnp.integrity.json')
        const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'))
        manifest.files['..\\escape'] = manifest.files['.pnp.cjs']
        manifest.files['../escape'] = manifest.files['.pnp.cjs']
        manifest.files['..'] = manifest.files['.pnp.cjs']
        manifest.files['nested/./file'] = manifest.files['.pnp.cjs']
        writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`)
        const errors = verifyProject(root)
        assert(
            errors.includes(
                'integrity manifest path is not normalized and project-relative: ..\\escape'
            )
        )
        assert(
            errors.includes(
                'integrity manifest path is not normalized and project-relative: ../escape'
            )
        )
        assert(
            errors.includes(
                'integrity manifest path is not normalized and project-relative: ..'
            )
        )
        assert(
            errors.includes(
                'integrity manifest path is not normalized and project-relative: nested/./file'
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a source symlink even when its target has identical bytes', () => {
    const { root } = makeProject()
    try {
        renameSync(join(root, '.pnp.cjs'), join(root, '.pnp.real.cjs'))
        symlinkSync('.pnp.real.cjs', join(root, '.pnp.cjs'))
        const errors = verifyProject(root)
        assert(
            errors.some(
                (error) =>
                    error ===
                    '.pnp.cjs: symbolic links are not supported in integrity-bound PnP inputs'
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects extra unmanifested unplugged files', () => {
    const { root } = makeUnpluggedProject()
    try {
        const extra = '.yarn/unplugged/pkg-npm-1.0.0/node_modules/pkg/extra.js'
        writeFileSync(join(root, extra), 'unexpected\n')
        const errors = verifyProject(root)
        assert(
            errors.some(
                (error) =>
                    error ===
                    `${extra}: unplugged file is present but absent from the integrity manifest`
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('rejects a manifest-bound unplugged tree absent from the PnP graph', () => {
    const { root } = makeUnpluggedProject()
    try {
        const foreign =
            '.yarn/unplugged/foreign-npm-1.0.0/node_modules/foreign/index.js'
        const content = 'module.exports = false\n'
        mkdirSync(
            join(
                root,
                '.yarn/unplugged/foreign-npm-1.0.0/node_modules/foreign'
            ),
            { recursive: true }
        )
        writeFileSync(join(root, foreign), content)
        const manifestPath = join(root, '.pnp.integrity.json')
        const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'))
        manifest.files[foreign] = {
            executable: false,
            sha512: hash(content),
            type: 'file',
        }
        writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`)
        const errors = verifyProject(root)
        assert(
            errors.includes(
                '.yarn/unplugged/foreign-npm-1.0.0: integrity-bound unplugged tree is not referenced by .pnp.data.json'
            )
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})

test('manifest generation rejects unplugged empty directories', () => {
    const { root } = makeUnpluggedProject()
    try {
        mkdirSync(
            join(root, '.yarn/unplugged/pkg-npm-1.0.0/node_modules/pkg/empty')
        )
        assert.throws(
            () => createIntegrityManifest(root),
            /empty directories cannot be preserved by a Bazel filegroup/
        )
    } finally {
        rmSync(root, { recursive: true, force: true })
    }
})
