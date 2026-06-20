import { execFileSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import assert from 'node:assert/strict'

const SCRIPT = path.resolve(process.argv[2])

let tmpDir
function setup() {
    tmpDir = mkdtempSync(path.join(tmpdir(), 'publish-manifest-test-'))
}
function teardown() {
    rmSync(tmpDir, { force: true, recursive: true })
}

function run(packageJson, workspaceYaml) {
    const pkgPath = path.join(tmpDir, 'package.json')
    const outPath = path.join(tmpDir, 'output.json')
    writeFileSync(pkgPath, JSON.stringify(packageJson))

    const args = [SCRIPT, pkgPath, outPath]
    if (workspaceYaml) {
        const yamlPath = path.join(tmpDir, 'pnpm-workspace.yaml')
        writeFileSync(yamlPath, workspaceYaml)
        args.push(yamlPath)
    }

    execFileSync(process.execPath, args, { stdio: 'pipe' })
    return JSON.parse(readFileSync(outPath, 'utf8'))
}

function runExpectError(packageJson, workspaceYaml) {
    const pkgPath = path.join(tmpDir, 'package.json')
    const outPath = path.join(tmpDir, 'output.json')
    writeFileSync(pkgPath, JSON.stringify(packageJson))

    const args = [SCRIPT, pkgPath, outPath]
    if (workspaceYaml) {
        const yamlPath = path.join(tmpDir, 'pnpm-workspace.yaml')
        writeFileSync(yamlPath, workspaceYaml)
        args.push(yamlPath)
    }

    try {
        execFileSync(process.execPath, args, { stdio: 'pipe' })
        throw new Error('Expected error but command succeeded')
    } catch (e) {
        if (e.message === 'Expected error but command succeeded') throw e
        return e.stderr.toString()
    }
}

const tests = []
function test(name, fn) {
    tests.push({ name, fn })
}

// --- Catalog resolution ---

test('resolves default catalog specifiers', () => {
    const result = run(
        {
            name: 'pkg',
            dependencies: { typescript: 'catalog:' },
        },
        'catalog:\n    typescript: ^5.9.3\n'
    )
    assert.equal(result.dependencies.typescript, '^5.9.3')
})

test('resolves named catalog specifiers', () => {
    const result = run(
        {
            name: 'pkg',
            dependencies: { react: 'catalog:react17' },
        },
        'catalogs:\n    react17:\n        react: ^17.0.2\n'
    )
    assert.equal(result.dependencies.react, '^17.0.2')
})

test('resolves catalogs across all dependency fields', () => {
    const result = run(
        {
            name: 'pkg',
            dependencies: { a: 'catalog:' },
            devDependencies: { b: 'catalog:' },
            optionalDependencies: { c: 'catalog:' },
            peerDependencies: { d: 'catalog:' },
        },
        'catalog:\n    a: ^1.0\n    b: ^2.0\n    c: ^3.0\n    d: ^4.0\n'
    )
    assert.equal(result.dependencies.a, '^1.0')
    assert.equal(result.devDependencies.b, '^2.0')
    assert.equal(result.optionalDependencies.c, '^3.0')
    assert.equal(result.peerDependencies.d, '^4.0')
})

test('leaves non-catalog specifiers unchanged', () => {
    const result = run(
        {
            name: 'pkg',
            dependencies: { lodash: '^4.17.21', typescript: 'catalog:' },
        },
        'catalog:\n    typescript: ^5.9.3\n'
    )
    assert.equal(result.dependencies.lodash, '^4.17.21')
    assert.equal(result.dependencies.typescript, '^5.9.3')
})

test('errors on missing catalog entry', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { missing: 'catalog:' },
        },
        'catalog:\n    typescript: ^5.9.3\n'
    )
    assert.ok(stderr.includes("No entry for 'missing' in catalog 'default'"))
})

test('errors on missing named catalog', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { react: 'catalog:nonexistent' },
        },
        'catalog:\n    typescript: ^5.9.3\n'
    )
    assert.ok(
        stderr.includes("No entry for 'react' in catalog 'nonexistent'")
    )
})

test('errors on recursive catalog reference', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { a: 'catalog:' },
        },
        'catalog:\n    a: "catalog:other"\n'
    )
    assert.ok(stderr.includes('Recursive catalog:'))
})

test('errors on workspace: protocol in catalog value', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { a: 'catalog:' },
        },
        'catalog:\n    a: "workspace:*"\n'
    )
    assert.ok(stderr.includes("Unsupported protocol 'workspace:'"))
})

test('errors on link: protocol in catalog value', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { a: 'catalog:' },
        },
        'catalog:\n    a: "link:../other"\n'
    )
    assert.ok(stderr.includes("Unsupported protocol 'link:'"))
})

test('errors on file: protocol in catalog value', () => {
    const stderr = runExpectError(
        {
            name: 'pkg',
            dependencies: { a: 'catalog:' },
        },
        'catalog:\n    a: "file:../other"\n'
    )
    assert.ok(stderr.includes("Unsupported protocol 'file:'"))
})

// --- publishConfig overlay ---

test('promotes whitelisted publishConfig fields', () => {
    const result = run({
        name: 'pkg',
        main: 'src/index.js',
        publishConfig: {
            main: 'dist/index.js',
            types: 'dist/index.d.ts',
            exports: { '.': './dist/index.js' },
        },
    })
    assert.equal(result.main, 'dist/index.js')
    assert.equal(result.types, 'dist/index.d.ts')
    assert.deepEqual(result.exports, { '.': './dist/index.js' })
    assert.equal(result.publishConfig, undefined)
})

test('keeps non-whitelisted publishConfig fields', () => {
    const result = run({
        name: 'pkg',
        publishConfig: {
            main: 'dist/index.js',
            registry: 'https://registry.npmjs.org',
            access: 'public',
        },
    })
    assert.equal(result.main, 'dist/index.js')
    assert.deepEqual(result.publishConfig, {
        registry: 'https://registry.npmjs.org',
        access: 'public',
    })
})

test('deletes publishConfig when all fields promoted', () => {
    const result = run({
        name: 'pkg',
        publishConfig: { main: 'dist/index.js', bin: './cli.js' },
    })
    assert.equal(result.main, 'dist/index.js')
    assert.equal(result.bin, './cli.js')
    assert.equal(result.publishConfig, undefined)
})

test('handles all whitelisted publishConfig fields', () => {
    const whitelist = [
        'bin', 'browser', 'cpu', 'engines', 'es2015', 'esnext', 'exports',
        'imports', 'libc', 'main', 'module', 'os', 'type', 'types', 'typings',
        'typesVersions', 'umd:main', 'unpkg',
    ]
    const publishConfig = {}
    for (const field of whitelist) {
        publishConfig[field] = `value-${field}`
    }
    const result = run({ name: 'pkg', publishConfig })
    for (const field of whitelist) {
        assert.equal(result[field], `value-${field}`, `field '${field}' should be promoted`)
    }
    assert.equal(result.publishConfig, undefined)
})

test('no-op when publishConfig is absent', () => {
    const result = run({ name: 'pkg', main: 'index.js' })
    assert.equal(result.main, 'index.js')
    assert.equal(result.publishConfig, undefined)
})

// --- Field stripping ---

test('strips pnpm field', () => {
    const result = run({
        name: 'pkg',
        pnpm: { overrides: { foo: '1.0.0' } },
    })
    assert.equal(result.pnpm, undefined)
})

test('strips packageManager field', () => {
    const result = run({
        name: 'pkg',
        packageManager: 'pnpm@10.0.0',
    })
    assert.equal(result.packageManager, undefined)
})

test('strips publish lifecycle scripts', () => {
    const result = run({
        name: 'pkg',
        scripts: {
            prepublish: 'echo prep',
            prepare: 'echo prepare',
            prepublishOnly: 'echo prepub',
            postpublish: 'echo post',
            build: 'tsc',
            test: 'jest',
        },
    })
    assert.deepEqual(result.scripts, { build: 'tsc', test: 'jest' })
})

test('deletes scripts when only lifecycle scripts remain', () => {
    const result = run({
        name: 'pkg',
        scripts: { prepublishOnly: 'tsc' },
    })
    assert.equal(result.scripts, undefined)
})

test('preserves scripts when no lifecycle scripts present', () => {
    const result = run({
        name: 'pkg',
        scripts: { build: 'tsc' },
    })
    assert.deepEqual(result.scripts, { build: 'tsc' })
})

// --- YAML parser ---

test('parses default catalog from workspace yaml', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: 'catalog:', b: 'catalog:' } },
        'catalog:\n    a: ^1.0\n    b: ^2.0\n'
    )
    assert.equal(result.dependencies.a, '^1.0')
    assert.equal(result.dependencies.b, '^2.0')
})

test('parses named catalogs from workspace yaml', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: 'catalog:foo', b: 'catalog:bar' } },
        'catalogs:\n    foo:\n        a: ^1.0\n    bar:\n        b: ^2.0\n'
    )
    assert.equal(result.dependencies.a, '^1.0')
    assert.equal(result.dependencies.b, '^2.0')
})

test('ignores non-catalog sections in workspace yaml', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: 'catalog:' } },
        [
            'packages:',
            '    - packages/*',
            'catalog:',
            '    a: ^1.0',
            'onlyBuiltDependencies:',
            '    - esbuild',
        ].join('\n')
    )
    assert.equal(result.dependencies.a, '^1.0')
})

test('handles comments in workspace yaml', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: 'catalog:' } },
        '# comment\ncatalog:\n    # another comment\n    a: ^1.0\n'
    )
    assert.equal(result.dependencies.a, '^1.0')
})

test('handles quoted keys and values in workspace yaml', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: 'catalog:' } },
        "catalog:\n    'a': '^1.0'\n"
    )
    assert.equal(result.dependencies.a, '^1.0')
})

test('returns empty catalogs when no catalog sections', () => {
    const result = run(
        { name: 'pkg', dependencies: { a: '^1.0' } },
        'packages:\n    - packages/*\n'
    )
    assert.equal(result.dependencies.a, '^1.0')
})

test('works without workspace yaml', () => {
    const result = run({ name: 'pkg', dependencies: { a: '^1.0' } })
    assert.equal(result.dependencies.a, '^1.0')
})

// --- Combined transforms ---

test('applies all transforms together', () => {
    const result = run(
        {
            name: '@mycorp/pkg',
            version: '1.0.0',
            main: 'src/index.js',
            publishConfig: {
                main: 'dist/index.js',
                registry: 'https://registry.npmjs.org',
            },
            dependencies: {
                typescript: 'catalog:',
                lodash: '^4.17.21',
            },
            pnpm: { overrides: {} },
            packageManager: 'pnpm@10.0.0',
            scripts: {
                build: 'tsc',
                prepublishOnly: 'npm run build',
            },
        },
        'catalog:\n    typescript: ^5.9.3\n'
    )
    assert.equal(result.name, '@mycorp/pkg')
    assert.equal(result.version, '1.0.0')
    assert.equal(result.main, 'dist/index.js')
    assert.deepEqual(result.publishConfig, {
        registry: 'https://registry.npmjs.org',
    })
    assert.equal(result.dependencies.typescript, '^5.9.3')
    assert.equal(result.dependencies.lodash, '^4.17.21')
    assert.equal(result.pnpm, undefined)
    assert.equal(result.packageManager, undefined)
    assert.deepEqual(result.scripts, { build: 'tsc' })
})

// --- Run tests ---

let passed = 0
let failed = 0

for (const t of tests) {
    setup()
    try {
        t.fn()
        passed++
    } catch (e) {
        failed++
        console.error(`FAIL: ${t.name}`)
        console.error(`  ${e.message}`)
    } finally {
        teardown()
    }
}

console.log(`\n${passed} passed, ${failed} failed, ${tests.length} total`)
if (failed > 0) process.exit(1)
