import { Archiver, create } from 'archiver'
import { createReadStream, createWriteStream } from 'node:fs'
import { readdir, readFile, realpath, stat } from 'node:fs/promises'
import * as path from 'node:path'

const [entriesPath, appLayerPath, nodeModulesLayerPath] = process.argv.slice(2)

const app = create('tar', { gzip: true })
app.pipe(createWriteStream(appLayerPath))
const app_structure = new Set<string>()

const node_modules = create('tar', { gzip: true })
node_modules.pipe(createWriteStream(nodeModulesLayerPath))
const node_modules_structure = new Set<string>()

const entries: {
    [k: string]: {
        is_source: boolean
        is_directory: boolean
        dest: string
        root?: string
    }
} = JSON.parse((await readFile(entriesPath)).toString())

function mkdirP(p: string, output: Archiver, structure: Set<string>) {
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
        output = output.append(
            null as any,
            { name: prev, type: 'directory' } as any
        )
    }
}

function findKeyByValue(value: string): string {
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

for (const key of Object.keys(entries).sort()) {
    const { dest, is_directory, is_source, root } = entries[key]
    const outputArchive = dest.indexOf('node_modules') ? node_modules : app
    const structure = dest.indexOf('node_modules')
        ? node_modules_structure
        : app_structure

    mkdirP(key, outputArchive, structure)

    if (is_directory) {
        for await (const sub_key of walk(dest)) {
            const new_key = path.join(key, sub_key)
            const new_dest = path.join(dest, sub_key)
            mkdirP(new_key, outputArchive, structure)
            outputArchive.append(createReadStream(new_dest), { name: new_key })
        }
        continue
    } else {
        const entryStat = await stat(dest)
        if (is_source) {
            outputArchive.append(createReadStream(dest), {
                name: key,
                stats: entryStat,
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
                outputArchive.symlink(
                    key.replace(/^\//, ''),
                    findKeyByValue(outputPath)
                )
            } else {
                outputArchive.append(createReadStream(dest), {
                    name: key,
                    stats: entryStat,
                })
            }
        }
    }
}

await app.finalize()
await node_modules.finalize()
