import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import fs from 'node:fs/promises'
import { syncBuiltinESMExports } from 'node:module'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { setImmediate } from 'node:timers/promises'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { test } from 'node:test'

if (process.argv[2] === '--run-splitter') {
    // Control only filesystem completion order. Use real readlink results, so
    // generated regular files take the splitter's asynchronous unused-input path.
    const order = JSON.parse(process.argv[4])
    const pending = new Map()
    const readlink = fs.readlink
    fs.readlink = (filename, ...args) =>
        new Promise((resolve, reject) => {
            pending.set(path.basename(filename), {
                filename,
                args,
                resolve,
                reject,
            })
            if (pending.size === order.length) {
                void (async () => {
                    for (const name of order) {
                        const item = pending.get(name)
                        await readlink(item.filename, ...item.args).then(
                            item.resolve,
                            item.reject
                        )
                        // Let the splitter consume this result before the next.
                        await setImmediate()
                    }
                })()
            }
        })
    syncBuiltinESMExports()
    await import(pathToFileURL(process.argv[3]))
} else {
    // Paths of the generated splitter and its entries.json, as rootpaths then
    // execpaths. The splitter reads entries.json and writes its outputs next to
    // it, by execpath relative to its cwd.
    const files = process.argv.slice(2)
    const generated = files
        .slice(0, files.length / 2)
        .find((f) => f.endsWith('_js_image_layer_splitter.mjs'))
    const entriesJson = files
        .slice(files.length / 2)
        .find((f) => f.endsWith('_entries.json'))
    const outputDir = path.dirname(entriesJson)

    test('splitter unused inputs do not depend on lookup completion order', async () => {
        const entries = {
            'app.runfiles/_main/source': { dest: 'source.txt', is_source: true },
            'app.runfiles/_main/node_modules/a': {
                dest: 'bazel-out/test/bin/a',
                is_source: false,
                root: 'bazel-out/test',
            },
            'app.runfiles/_main/node_modules/b': {
                dest: 'bazel-out/test/bin/b',
                is_source: false,
                root: 'bazel-out/test',
            },
            'app.runfiles/_main/source-copy': {
                dest: 'source.txt',
                is_source: true,
            },
        }
        const runs = []
        for (const order of [
            ['a', 'b'],
            ['b', 'a'],
        ]) {
            const directory = await fs.mkdtemp(
                path.join(process.env.TEST_TMPDIR || tmpdir(), 'splitter-')
            )
            try {
                await fs.mkdir(path.join(directory, 'bazel-out/test/bin'), {
                    recursive: true,
                })
                for (const { dest } of Object.values(entries)) {
                    await fs.writeFile(path.join(directory, dest), 'content')
                }
                await fs.mkdir(path.join(directory, outputDir), {
                    recursive: true,
                })
                await fs.writeFile(
                    path.join(directory, entriesJson),
                    JSON.stringify(entries)
                )
                const result = spawnSync(
                    process.execPath,
                    [
                        fileURLToPath(import.meta.url),
                        '--run-splitter',
                        path.resolve(generated),
                        JSON.stringify(order),
                    ],
                    { cwd: directory, encoding: 'utf8', timeout: 10000 }
                )
                assert.equal(
                    result.status,
                    0,
                    result.stderr || String(result.error)
                )
                const outputs = {}
                for (const name of await fs.readdir(
                    path.join(directory, outputDir)
                )) {
                    if (name.endsWith('.mtree') || name.endsWith('.txt')) {
                        outputs[name] = await fs.readFile(
                            path.join(directory, outputDir, name),
                            'utf8'
                        )
                    }
                }
                runs.push(outputs)
            } finally {
                await fs.rm(directory, { recursive: true, force: true })
            }
        }
        assert.deepEqual(
            runs[0],
            runs[1],
            'splitter outputs must not depend on lookup completion order'
        )
        const output = (suffix) =>
            Object.entries(runs[0]).find(([name]) => name.endsWith(suffix))[1]
        assert.equal(
            output('_splitter_unused_inputs.txt'),
            'bazel-out/test/bin/a\nbazel-out/test/bin/b\nsource.txt\nsource.txt\n'
        )
        // Each layer lists every entry it doesn't own, in entry order.
        assert.equal(
            output('_app_unused_inputs.txt'),
            'bazel-out/test/bin/a\nbazel-out/test/bin/b\n'
        )
        assert.equal(
            output('_node_modules_unused_inputs.txt'),
            'source.txt\nsource.txt\n'
        )
    })
}
