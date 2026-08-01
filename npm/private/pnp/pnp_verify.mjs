/**
 * Verifies a checked-in Yarn PnP project without executing Yarn.
 *
 * The integrity manifest binds the executable resolver, resolution data,
 * Yarn config, lockfile, every cache archive, and every referenced unplugged
 * file. yarn.lock remains an independent checksum source for archives that
 * carry a Yarn checksum.
 */
import { createHash } from 'node:crypto'
import {
    existsSync,
    lstatSync,
    readFileSync,
    readdirSync,
    readlinkSync,
    statSync,
} from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join, posix, relative, resolve, sep, win32 } from 'node:path'
import { fileURLToPath } from 'node:url'

const REQUIRED_INTEGRITY_FILES = [
    '.pnp.cjs',
    '.pnp.data.json',
    '.yarnrc.yml',
    'yarn.lock',
]

export function sha512(path) {
    return createHash('sha512').update(readFileSync(path)).digest('hex')
}

function executable(path) {
    return (statSync(path).mode & 0o111) !== 0
}

function normalizeRelative(path) {
    return path.split(sep).join('/').replace(/^\.\//, '')
}

function isSafeRelative(path) {
    const segments = path.split('/')
    return (
        path.length > 0 &&
        !path.includes('\\') &&
        !path.includes('\0') &&
        !path.endsWith('/') &&
        !posix.isAbsolute(path) &&
        !win32.isAbsolute(path) &&
        segments.every(
            (segment) => segment !== '' && segment !== '.' && segment !== '..'
        ) &&
        posix.normalize(path) === path
    )
}

export function listFiles(root, { strictSourceTree = false } = {}) {
    if (!existsSync(root)) return []
    const files = []
    const visit = (path) => {
        const entry = lstatSync(path)
        if (entry.isSymbolicLink()) {
            if (strictSourceTree)
                throw new Error(
                    `${path}: symbolic links are not supported in integrity-bound PnP inputs`
                )
            const followed = statSync(path)
            if (followed.isDirectory()) {
                const children = readdirSync(path).sort()
                for (const child of children) visit(join(path, child))
            } else if (followed.isFile()) {
                files.push(path)
            }
        } else if (entry.isDirectory()) {
            const children = readdirSync(path).sort()
            if (strictSourceTree && children.length === 0)
                throw new Error(
                    `${path}: empty directories cannot be preserved by a Bazel filegroup; add a checked-in marker file`
                )
            for (const child of children) visit(join(path, child))
        } else if (entry.isFile()) {
            files.push(path)
        } else if (strictSourceTree) {
            throw new Error(
                `${path}: only regular files are supported in integrity-bound PnP inputs`
            )
        }
    }
    visit(root)
    return files
}

function unpluggedRootOf(location) {
    const normalized = location.replaceAll('\\', '/')
    const match = normalized.match(/^\.\/(.+?\/unplugged\/[^/]+)(?:\/|$)/)
    return match ? match[1] : null
}

function readLockChecksums(root) {
    const checksums = new Map()
    const errors = []
    const lock = readFileSync(join(root, 'yarn.lock'), 'utf8')
    let resolution = null
    for (const line of lock.split('\n')) {
        const resolutionMatch = line.match(/^ {2}resolution: "?([^"\n]+)"?$/)
        if (resolutionMatch) {
            resolution = resolutionMatch[1]
            continue
        }
        const checksumMatch = line.match(/^ {2}checksum:\s*(.*?)\s*$/)
        if (checksumMatch) {
            const raw = checksumMatch[1].replace(/^(["'])(.*)\1$/, '$2')
            const valid = raw.match(/^(?:[0-9a-z]+\/)?([0-9a-f]{128})$/)
            if (!resolution)
                errors.push(
                    `yarn.lock checksum ${raw} appears before its resolution`
                )
            else if (!valid)
                errors.push(
                    `${resolution}: yarn.lock checksum must be an optional lowercase cache-key prefix and 128 lowercase hexadecimal characters, got ${raw}`
                )
            else checksums.set(resolution, valid[1])
        }
        if (!line.startsWith(' ')) resolution = null
    }
    return { checksums, errors }
}

function devirtualize(reference) {
    if (!reference.startsWith('virtual:')) return reference
    const anchor = reference.indexOf('#')
    return anchor === -1 ? null : reference.slice(anchor + 1)
}

function readIntegrity(root) {
    const path = join(root, '.pnp.integrity.json')
    const data = JSON.parse(readFileSync(path, 'utf8'))
    if (
        data.version !== 1 ||
        data.files === null ||
        typeof data.files !== 'object' ||
        Array.isArray(data.files)
    ) {
        throw new Error(
            '.pnp.integrity.json must contain {"version": 1, "files": {...}}'
        )
    }
    return data.files
}

function verifyIntegrity(root, files) {
    const errors = []
    for (const required of REQUIRED_INTEGRITY_FILES) {
        if (!(required in files))
            errors.push(`integrity manifest is missing ${required}`)
    }
    for (const [path, expected] of Object.entries(files).sort(([a], [b]) =>
        a.localeCompare(b)
    )) {
        if (!isSafeRelative(path)) {
            errors.push(
                `integrity manifest path is not normalized and project-relative: ${path}`
            )
            continue
        }
        if (
            expected === null ||
            typeof expected !== 'object' ||
            Array.isArray(expected) ||
            expected.type !== 'file' ||
            !/^[0-9a-f]{128}$/.test(expected.sha512) ||
            typeof expected.executable !== 'boolean'
        ) {
            errors.push(
                `${path}: integrity entry must contain type=file, a 128-character lowercase sha512, and executable=true|false`
            )
            continue
        }
        const absolute = join(root, path)
        if (!existsSync(absolute)) {
            errors.push(`${path}: integrity-bound file is missing`)
            continue
        }
        const logical = lstatSync(absolute)
        if (logical.isSymbolicLink()) {
            const runfilesRoot = process.env.RUNFILES_DIR
                ? resolve(process.env.RUNFILES_DIR)
                : null
            const inRunfiles =
                runfilesRoot &&
                (absolute === runfilesRoot ||
                    absolute.startsWith(`${runfilesRoot}${sep}`))
            const firstTarget = resolve(
                dirname(absolute),
                readlinkSync(absolute)
            )
            if (!inRunfiles || lstatSync(firstTarget).isSymbolicLink()) {
                errors.push(
                    `${path}: symbolic links are not supported in integrity-bound PnP inputs`
                )
                continue
            }
        }
        if (!statSync(absolute).isFile()) {
            errors.push(`${path}: integrity-bound entry is not a regular file`)
            continue
        }
        const actual = sha512(absolute)
        if (actual !== expected.sha512)
            errors.push(
                `${path}: integrity mismatch\n  manifest: ${expected.sha512}\n  computed: ${actual}`
            )
        const actualExecutable = executable(absolute)
        if (actualExecutable !== expected.executable)
            errors.push(
                `${path}: executable mode mismatch (manifest ${expected.executable}, actual ${actualExecutable})`
            )
    }
    return errors
}

function exactTreeFiles(root, relativeRoot) {
    const absoluteRoot = join(root, relativeRoot)
    return listFiles(absoluteRoot)
        .map((path) => normalizeRelative(relative(root, path)))
        .sort()
}

export function createIntegrityManifest(
    root,
    { cacheRoot = '.yarn/cache' } = {}
) {
    const data = JSON.parse(readFileSync(join(root, '.pnp.data.json'), 'utf8'))
    const paths = new Set(REQUIRED_INTEGRITY_FILES)

    for (const path of listFiles(join(root, cacheRoot), {
        strictSourceTree: true,
    })) {
        if (path.endsWith('.zip'))
            paths.add(normalizeRelative(relative(root, path)))
    }
    for (const [, references] of data.packageRegistryData) {
        for (const [, info] of references) {
            const unpluggedRoot = unpluggedRootOf(info.packageLocation)
            if (unpluggedRoot) {
                for (const path of listFiles(join(root, unpluggedRoot), {
                    strictSourceTree: true,
                }))
                    paths.add(normalizeRelative(relative(root, path)))
            }
        }
    }

    const files = {}
    for (const path of [...paths].sort()) {
        const absolute = join(root, path)
        if (
            lstatSync(absolute).isSymbolicLink() ||
            !statSync(absolute).isFile()
        )
            throw new Error(
                `${path}: only regular files are supported in integrity-bound PnP inputs`
            )
        files[path] = {
            executable: executable(absolute),
            sha512: sha512(absolute),
            type: 'file',
        }
    }
    return { version: 1, files }
}

export function verifyProject(root) {
    const errors = []
    let integrity
    try {
        integrity = readIntegrity(root)
    } catch (error) {
        return [error.message]
    }
    errors.push(...verifyIntegrity(root, integrity))

    // Never execute the checked-in resolver until its exact bytes and sibling
    // data/config/lock inputs have passed integrity verification.
    if (
        errors.some((error) =>
            REQUIRED_INTEGRITY_FILES.some(
                (path) =>
                    error.startsWith(`${path}:`) || error.endsWith(` ${path}`)
            )
        )
    )
        return errors

    const pnpData = JSON.parse(
        readFileSync(join(root, '.pnp.data.json'), 'utf8')
    )
    const lockChecksumResult = readLockChecksums(root)
    const lockChecksums = lockChecksumResult.checksums
    errors.push(...lockChecksumResult.errors)
    const require = createRequire(import.meta.url)
    let pnpApi
    try {
        pnpApi = require(join(root, '.pnp.cjs'))
    } catch (error) {
        errors.push(
            `.pnp.cjs failed to load its integrity-bound sibling data: ${error.message}`
        )
        return errors
    }

    const manifestPaths = new Set(Object.keys(integrity))
    const referencedArchives = new Map()
    const unpluggedRoots = new Set()
    const unpluggedSourceDigests = new Map()
    for (const [name, references] of pnpData.packageRegistryData) {
        if (name === null) continue
        for (const [reference, info] of references) {
            if (reference === null) continue
            const physicalReference = devirtualize(reference)
            if (physicalReference === null) {
                errors.push(`${name}@${reference}: malformed virtual reference`)
                continue
            }

            const rawLocation = resolve(root, info.packageLocation)
            let physicalLocation = rawLocation
            try {
                const resolvedVirtual = pnpApi.resolveVirtual(rawLocation)
                if (resolvedVirtual !== null) {
                    if (typeof resolvedVirtual !== 'string')
                        throw new Error(
                            `returned ${typeof resolvedVirtual}, expected a path or null`
                        )
                    physicalLocation = resolvedVirtual
                }
            } catch (error) {
                errors.push(
                    `${name}@${reference}: .pnp.cjs could not resolve packageLocation ${info.packageLocation}: ${error.message}`
                )
                continue
            }
            const archiveMarker = `.zip${sep}node_modules${sep}`
            const archiveIndex = physicalLocation.indexOf(archiveMarker)
            if (archiveIndex !== -1) {
                const archive = physicalLocation.slice(
                    0,
                    archiveIndex + '.zip'.length
                )
                const archiveRelative = normalizeRelative(
                    relative(root, archive)
                )
                referencedArchives.set(
                    archiveRelative,
                    `${name}@${physicalReference}`
                )
            }

            const unpluggedRoot = unpluggedRootOf(info.packageLocation)
            if (unpluggedRoot) {
                unpluggedRoots.add(unpluggedRoot)
                const locator = `${name}@${physicalReference}`
                const checksum = lockChecksums.get(locator)
                if (checksum) {
                    if (!unpluggedSourceDigests.has(checksum))
                        unpluggedSourceDigests.set(checksum, new Set())
                    unpluggedSourceDigests.get(checksum).add(locator)
                }
            }
        }
    }

    const manifestArchives = [...manifestPaths]
        .filter((path) => path.endsWith('.zip'))
        .sort()
    const remainingUnpluggedSourceDigests = new Map(unpluggedSourceDigests)
    for (const path of manifestArchives) {
        const digest = integrity[path]?.sha512
        if (referencedArchives.has(path)) {
            remainingUnpluggedSourceDigests.delete(digest)
        } else if (remainingUnpluggedSourceDigests.has(digest)) {
            remainingUnpluggedSourceDigests.delete(digest)
        } else {
            errors.push(
                `${path}: integrity-bound cache archive is neither referenced by .pnp.data.json nor the unique lock-backed source for an active unplugged package`
            )
        }
    }
    for (const [digest, locators] of remainingUnpluggedSourceDigests) {
        errors.push(
            `${[...locators]
                .sort()
                .join(
                    ', '
                )}: active unplugged package has no cache archive matching yarn.lock checksum ${digest}`
        )
    }
    const cacheDirectories = new Set(
        manifestArchives.map((path) => dirname(path))
    )
    for (const directory of cacheDirectories) {
        const actual = existsSync(join(root, directory))
            ? readdirSync(join(root, directory))
                  .filter((name) => name.endsWith('.zip'))
                  .map((name) => normalizeRelative(join(directory, name)))
                  .sort()
            : []
        const expected = manifestArchives.filter(
            (path) => dirname(path) === directory
        )
        for (const path of actual)
            if (!expected.includes(path))
                errors.push(
                    `${path}: cache archive is present but absent from the integrity manifest`
                )
        for (const path of expected)
            if (!actual.includes(path))
                errors.push(`${path}: integrity-bound cache archive is missing`)
    }

    for (const [archive, locator] of referencedArchives) {
        if (!manifestPaths.has(archive)) {
            errors.push(
                `${locator}: referenced cache archive ${archive} is absent from the integrity manifest`
            )
            continue
        }
        const expected = lockChecksums.get(locator)
        if (!expected) continue // Integrity manifest covers valid no-checksum Yarn entries.
        const actual = sha512(join(root, archive))
        if (actual !== expected)
            errors.push(
                `${locator}: yarn.lock checksum mismatch for ${archive}\n  yarn.lock: ${expected}\n  computed:  ${actual}`
            )
    }

    const manifestUnpluggedRoots = new Set(
        [...manifestPaths]
            .map((path) => unpluggedRootOf(`./${path}`))
            .filter((path) => path !== null)
    )
    for (const unpluggedRoot of [...manifestUnpluggedRoots].sort()) {
        if (!unpluggedRoots.has(unpluggedRoot))
            errors.push(
                `${unpluggedRoot}: integrity-bound unplugged tree is not referenced by .pnp.data.json`
            )
    }
    const unpluggedDirectories = new Set(['.yarn/unplugged'])
    for (const unpluggedRoot of [...unpluggedRoots, ...manifestUnpluggedRoots])
        unpluggedDirectories.add(dirname(unpluggedRoot))
    for (const directory of unpluggedDirectories) {
        const actual = existsSync(join(root, directory))
            ? exactTreeFiles(root, directory)
            : []
        const expected = [...manifestPaths]
            .filter((path) => path.startsWith(`${directory}/`))
            .sort()
        for (const path of actual)
            if (!expected.includes(path))
                errors.push(
                    `${path}: unplugged file is present but absent from the integrity manifest`
                )
        for (const path of expected)
            if (!actual.includes(path))
                errors.push(
                    `${path}: integrity-bound unplugged file is missing`
                )
    }
    for (const unpluggedRoot of [...unpluggedRoots].sort()) {
        const actual = exactTreeFiles(root, unpluggedRoot)
        const expected = [...manifestPaths]
            .filter((path) => path.startsWith(`${unpluggedRoot}/`))
            .sort()
        if (actual.length === 0)
            errors.push(
                `${unpluggedRoot}: referenced unplugged tree is missing or empty`
            )
        if (expected.length === 0)
            errors.push(
                `${unpluggedRoot}: referenced unplugged tree has no integrity-bound files`
            )
    }

    return errors
}

function main() {
    const root = resolve(process.env.PNP_ROOT || '.')
    const errors = verifyProject(root)
    if (errors.length > 0) {
        console.error(
            `pnp verification failed:\n${errors
                .map((error) => `  ${error}`)
                .join('\n')}`
        )
        process.exitCode = 1
    } else {
        console.log(
            'pnp verification passed: resolver, graph, config, cache, and unplugged inputs match their checked-in integrity sources'
        )
    }
}

if (
    process.argv[1] &&
    resolve(process.argv[1]) === fileURLToPath(import.meta.url)
)
    main()
