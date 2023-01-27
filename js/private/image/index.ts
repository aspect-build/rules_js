import { pathToFileURL } from 'node:url'
import { Archiver, create } from 'archiver'
import { createReadStream, createWriteStream, Stats } from 'node:fs'
import { readdir, readFile, realpath, stat } from 'node:fs/promises'
import * as path from 'node:path'

const MTIME = new Date(0)
const NOBYTES = Buffer.concat([])

type hiddenkey = any
export type Entries = {
    [k: string]: {
        is_source: boolean
        is_directory: boolean
        dest: string
        root?: string
    }
}

function mkdirP(
    p: string,
    output: Archiver,
    structure: Set<string>,
    mtime: Date
) {
    const dirname = path.dirname(p).split('/')
    let prev = '/'
    for (const part of dirname) {
        if (!part) {
            continue
        }
        prev = path.join(prev, part)
        if (structure.has(prev)) {
            continue
        }
        structure.add(prev)
        output.append(NOBYTES, {
            name: prev,
            date: mtime,
            ['type' as hiddenkey]: 'directory',
        })
    }
}

function findKeyByValue(entries: Entries, value: string): string {
    for (const [key, { dest: val }] of Object.entries(entries)) {
        if (val == value) {
            return key
        }
    }
    throw new Error(
        `couldn't map ${value} to a path. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`
    )
}

async function* walk(dir: string, accumulate = '') {
    const dirents = await readdir(dir, { withFileTypes: true })
    for (const dirent of dirents) {
        if (dirent.isDirectory()) {
            yield* walk(
                path.join(dir, dirent.name),
                path.join(accumulate, dirent.name)
            )
        } else {
            yield path.join(accumulate, dirent.name)
        }
    }
}

function hermeticStat(stat: Stats): Stats {
    return {
        size: stat.size,
        mode: stat.mode,
        mtime: MTIME,
        isDirectory: stat.isDirectory,
        isFile: stat.isFile,
        isSymbolicLink: stat.isSymbolicLink,
    } as Stats
}

export async function build(
    entries: Entries,
    appLayerPath: string,
    nodeModulesLayerPath: string,
    mtime = MTIME
) {
    const app = create('tar', { gzip: true })
    app.pipe(createWriteStream(appLayerPath))
    const app_structure = new Set<string>()

    const node_modules = create('tar', { gzip: true })
    node_modules.pipe(createWriteStream(nodeModulesLayerPath))
    const node_modules_structure = new Set<string>()

    for (const key of Object.keys(entries).sort()) {
        const { dest, is_directory, is_source, root } = entries[key]
        const outputArchive =
            dest.indexOf('node_modules') != -1 ? node_modules : app
        const structure =
            dest.indexOf('node_modules') != -1
                ? node_modules_structure
                : app_structure

        mkdirP(key, outputArchive, structure, mtime)

        if (is_directory) {
            for await (const sub_key of walk(dest)) {
                const new_key = path.join(key, sub_key)
                const new_dest = path.join(dest, sub_key)
                mkdirP(new_key, outputArchive, structure, mtime)
                const entryStat = await stat(new_dest)
                outputArchive.append(createReadStream(new_dest), {
                    name: new_key,
                    date: mtime,
                    mode: entryStat.mode,
                    stats: hermeticStat(entryStat),
                })
            }
            continue
        } else {
            const entryStat = await stat(dest)
            if (is_source) {
                outputArchive.append(createReadStream(dest), {
                    name: key,
                    mode: entryStat.mode,
                    date: mtime,
                    stats: hermeticStat(entryStat),
                })
            } else {
                if (!root) {
                    // everything except sources should have
                    throw new Error(
                        `unexpected entry format. ${JSON.stringify(
                            entries[key]
                        )}. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`
                    )
                }
                let realp = await realpath(dest)
                const outputPath = realp.slice(realp.indexOf(root))
                if (outputPath != dest) {
                    // .symlink function from archiver does not support setting the mtime which leads to non-reproducible builds.
                    // therefore we'll use .append instead.
                    outputArchive.append(NOBYTES, {
                        ['type' as hiddenkey]: 'symlink',
                        name: key.replace(/\\/g, '/').replace(/^\//, ''),
                        ['linkname' as hiddenkey]: findKeyByValue(
                            entries,
                            outputPath
                        ).replace(/\\/g, '/'),
                        date: mtime,
                        mode: entryStat.mode,
                        stats: hermeticStat(entryStat),
                    })
                } else {
                    outputArchive.append(createReadStream(dest), {
                        name: key,
                        mode: entryStat.mode,
                        date: mtime,
                        stats: hermeticStat(entryStat),
                    })
                }
            }
        }
    }
    await app.finalize()
    await node_modules.finalize()
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
    const [entriesPath, appLayerPath, nodeModulesLayerPath] =
        process.argv.slice(2)

    const entries: Entries = JSON.parse(
        (await readFile(entriesPath)).toString()
    )

    build(entries, appLayerPath, nodeModulesLayerPath)
}
