import { createReadStream, createWriteStream } from 'node:fs'
import { readdir, readFile, realpath, stat } from 'node:fs/promises'
import * as path from 'node:path'
import { Readable, Stream } from 'node:stream'
import { pathToFileURL } from 'node:url'
import { createGzip } from 'node:zlib'
import { pack, Pack } from 'tar-stream'

const MTIME = new Date(0)

type HermeticStat = {
    mtime: Date
    mode: number
    size?: number
}

type Entry = {
    is_source: boolean
    is_directory: boolean
    dest: string
    root?: string
    remove_non_hermetic_lines?: boolean
}
type Entries = { [path: string]: Entry }

type Compression = 'gzip' | 'none'

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

function add_parents(name: string, pkg: Pack, existing_paths: Set<string>) {
    const segments = path.dirname(name).split('/')
    let prev = ''
    const stats: HermeticStat = {
        // this is an intermediate directory and bazel does not allow specifying
        // modes for intermediate directories.
        mode: 0o755,
        mtime: MTIME,
    }
    for (const part of segments) {
        if (!part) {
            continue
        }
        prev = path.join(prev, part)
        // check if the directory has been has been created before.
        if (existing_paths.has(prev)) {
            continue
        }

        existing_paths.add(prev)
        add_directory(prev, pkg, stats)
    }
}

function add_directory(name: string, pkg: Pack, stats: HermeticStat) {
    pkg.entry({
        type: 'directory',
        name: name.replace(/^\//, ''),
        mode: stats.mode,
        mtime: MTIME,
    }).end()
}

function add_symlink(
    name: string,
    linkname: string,
    pkg: Pack,
    stats: HermeticStat
) {
    pkg.entry({
        type: 'symlink',
        name: name.replace(/^\//, ''),
        linkname: linkname,
        mode: stats.mode,
        mtime: MTIME,
    }).end()
}

function add_file(
    name: string,
    content: Readable,
    pkg: Pack,
    stats: HermeticStat
) {
    return new Promise((resolve, reject) => {
        const entry = pkg.entry(
            {
                type: 'file',
                name: name.replace(/^\//, ''),
                mode: stats.mode,
                size: stats.size,
                mtime: MTIME,
            },
            (err) => {
                if (err) {
                    reject(err)
                } else {
                    resolve(undefined)
                }
            }
        )
        content.pipe(entry)
    })
}

export async function build(
    entries: Entries,
    appLayerPath: string,
    nodeModulesLayerPath: string,
    compression: Compression
) {
    const app = pack()
    const nm = pack()

    const app_existing_paths = new Set<string>()
    const nm_existing_paths = new Set<string>()

    let app_output: Stream = app,
        nm_output: Stream = nm

    if (compression == 'gzip') {
        app_output = app_output.pipe(createGzip())
        nm_output = nm_output.pipe(createGzip())
    }

    app_output.pipe(createWriteStream(appLayerPath))
    nm_output.pipe(createWriteStream(nodeModulesLayerPath))

    for (const key of Object.keys(entries).sort()) {
        const {
            dest,
            is_directory,
            is_source,
            root,
            remove_non_hermetic_lines,
        } = entries[key]

        const output = dest.indexOf('node_modules') != -1 ? nm : app
        const existing_paths =
            dest.indexOf('node_modules') != -1
                ? nm_existing_paths
                : app_existing_paths

        // its a treeartifact. expand it and add individual entries.
        if (is_directory) {
            for await (const sub_key of walk(dest)) {
                const new_key = path.join(key, sub_key)
                const new_dest = path.join(dest, sub_key)

                add_parents(new_key, output, existing_paths)

                const stats = await stat(new_dest)
                await add_file(
                    new_key,
                    createReadStream(new_dest),
                    output,
                    stats
                )
            }
            continue
        }

        // create parents of current path.
        add_parents(key, output, existing_paths)

        // A source file from workspace, not an output of a target.
        if (is_source) {
            const stats = await stat(dest)
            await add_file(key, createReadStream(dest), output, stats)
            continue
        }

        // root indicates where the generated source comes from. it looks like
        // `bazel-out/darwin_arm64-fastbuild` when there's no transition.
        if (!root) {
            // everything except sources should have
            throw new Error(
                `unexpected entry format. ${JSON.stringify(
                    entries[key]
                )}. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`
            )
        }

        const realp = await realpath(dest)
        const output_path = realp.slice(realp.indexOf(root))
        if (output_path != dest) {
            const stats = await stat(dest)
            const linkname = findKeyByValue(entries, output_path)
            add_symlink(key, linkname, output, stats)
        } else {
            const stats = await stat(dest)
            let stream: Readable = createReadStream(dest)

            if (remove_non_hermetic_lines) {
                const content = await readFile(dest)
                const replaced = Buffer.from(
                    content
                        .toString()
                        .replace(
                            /.*JS_BINARY__TARGET_CPU=".*?"/g,
                            `export JS_BINARY__TARGET_CPU="$(uname -m)"`
                        )
                        .replace(
                            /.*JS_BINARY__BINDIR=".*"/g,
                            `export JS_BINARY__BINDIR="$(pwd)"`
                        )
                )
                stream = Readable.from(replaced)
                stats.size = replaced.byteLength
            }

            await add_file(key, stream, output, stats)
        }
    }

    app.finalize()
    nm.finalize()
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
    const [entriesPath, appLayerPath, nodeModulesLayerPath, compression] =
        process.argv.slice(2)

    const raw_entries = await readFile(entriesPath)
    const entries: Entries = JSON.parse(raw_entries.toString())
    build(
        entries,
        appLayerPath,
        nodeModulesLayerPath,
        compression as Compression
    )
}
