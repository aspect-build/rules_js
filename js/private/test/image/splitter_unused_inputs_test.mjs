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
    test('splitter unused inputs do not depend on lookup completion order', async () => {
        const directory = await fs.mkdtemp(
            path.join(process.env.TEST_TMPDIR || tmpdir(), 'splitter-')
        )
        try {
            const entries = {
                'app/source': { dest: 'source.txt', is_source: true },
                'app/a': {
                    dest: 'bazel-out/test/bin/a',
                    is_source: false,
                    root: 'bazel-out/test',
                },
                'app/b': {
                    dest: 'bazel-out/test/bin/b',
                    is_source: false,
                    root: 'bazel-out/test',
                },
                'app/source-copy': { dest: 'source.txt', is_source: true },
            }
            await fs.mkdir(path.join(directory, 'bazel-out/test/bin'), {
                recursive: true,
            })
            for (const { dest } of Object.values(entries)) {
                await fs.writeFile(path.join(directory, dest), 'content')
            }
            await fs.writeFile(
                path.join(directory, 'entries.json'),
                JSON.stringify(entries)
            )
            // Expand the production template with one catch-all layer.
            let splitter = await fs.readFile(process.argv[2], 'utf8')
            const substitutions = {
                '{{UID}}': '0',
                '{{GID}}': '0',
                '{{DIRECTORY_MODE}}': '0755',
                '{{FILE_MODE}}': '0644',
                '{{RUNFILES_DIR}}': 'app',
                '{{REPO_NAME}}': '_main',
                '{{ENTRIES}}': 'entries.json',
                '{{PRESERVE_SYMLINKS}}': '.*',
                '{{UNUSED_INPUTS}}': 'unused_inputs.txt',
                '/*{{VARIABLES}}*/': 'const layer = new Set(["#mtree"]);',
                '/*{{PICK_STATEMENTS}}*/': 'mtree = layer;',
                '/*{{WRITE_STATEMENTS}}*/':
                    'writeFile("layer.mtree", Array.from(layer).sort().join("\\n")),',
            }
            for (const [key, value] of Object.entries(substitutions)) {
                splitter = splitter.replaceAll(key, value)
            }
            const script = path.join(directory, 'splitter.mjs')
            await fs.writeFile(script, splitter)
            const outputs = []
            for (const order of [
                ['a', 'b'],
                ['b', 'a'],
            ]) {
                const result = spawnSync(
                    process.execPath,
                    [
                        fileURLToPath(import.meta.url),
                        '--run-splitter',
                        script,
                        JSON.stringify(order),
                    ],
                    { cwd: directory, encoding: 'utf8', timeout: 10000 }
                )
                assert.equal(
                    result.status,
                    0,
                    result.stderr || String(result.error)
                )
                outputs.push({
                    unused: await fs.readFile(
                        path.join(directory, 'unused_inputs.txt'),
                        'utf8'
                    ),
                    mtree: await fs.readFile(
                        path.join(directory, 'layer.mtree'),
                        'utf8'
                    ),
                })
            }
            assert.equal(outputs[0].mtree, outputs[1].mtree)
            assert.equal(
                outputs[0].unused,
                outputs[1].unused,
                'unused-input bytes must not depend on lookup completion order'
            )
            assert.equal(
                outputs[0].unused,
                'bazel-out/test/bin/a\nbazel-out/test/bin/b\nsource.txt\nsource.txt\n'
            )
        } finally {
            await fs.rm(directory, { recursive: true, force: true })
        }
    })
}
