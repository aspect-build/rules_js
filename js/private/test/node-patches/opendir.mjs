/**
 * @license
 * Copyright 2019 The Bazel Authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import * as assert from 'node:assert'
import * as fs from 'node:fs'
import { withFixtures } from 'inline-fixtures'
import * as path from 'node:path'
import * as util from 'node:util'

import { patcher } from '../../node-patches/src/fs.cjs'

// We don't want to bring jest into this repo so we just fake the describe and it functions here
async function describe(_, fn) {
    await fn()
}
async function it(_, fn) {
    await fn()
}

describe('testing opendir', async () => {
    await it('can opendir dirent in root', async () => {
        await withFixtures(
            {
                a: { apples: 'contents' },
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)
                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([fixturesDir])

                let dir
                dir = await util.promisify(fs.opendir)(
                    path.join(fixturesDir, 'a')
                )
                const entry1 = await dir.read()
                const entry2 = await new Promise((resolve, reject) => {
                    dir.read(function (err, dirent) {
                        if (err) {
                            reject(err)
                        } else {
                            resolve(dirent)
                        }
                    })
                })
                const empty = await dir.read()

                let names = [entry1.name, entry2.name]
                names.sort()
                assert.deepStrictEqual(names, ['apples', 'link'])

                let maybeLink = entry1.name === 'link' ? entry1 : entry2
                assert.ok(maybeLink.isSymbolicLink())

                assert.ok(!empty, 'last read should be falsey')

                // Assert reading via URL produces the same (first) result.
                dir = await util.promisify(fs.opendir)(
                    new URL(`file://${path.join(fixturesDir, 'a')}`)
                )
                assert.equal(entry1.name, (await dir.read()).name)

                revertPatches()
            }
        )
    })

    await it('can opendir dirent link out of root', async () => {
        await withFixtures(
            {
                a: { apples: 'contents' },
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)
                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([path.join(fixturesDir, 'a')])

                let dir
                dir = await util.promisify(fs.opendir)(
                    path.join(fixturesDir, 'a')
                )
                const entry1 = await dir.read()
                const entry2 = await new Promise((resolve, reject) => {
                    dir.read(function (err, dirent) {
                        if (err) {
                            reject(err)
                        } else {
                            resolve(dirent)
                        }
                    })
                })
                const empty = await dir.read()

                let names = [entry1.name, entry2.name]
                names.sort()

                assert.ok(!empty)
                assert.deepStrictEqual(names, ['apples', 'link'])

                let maybeLink = entry1.name === 'link' ? entry1 : entry2

                console.error(entry1, entry2)
                assert.ok(!maybeLink.isSymbolicLink())

                revertPatches()
            }
        )
    })

    await it('can async iterate opendir', async () => {
        await withFixtures(
            {
                a: { apples: 'contents' },
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)
                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([path.join(fixturesDir)])

                const dir = await util.promisify(fs.opendir)(
                    path.join(fixturesDir, 'a')
                )
                const names = []
                for await (const entry of dir) {
                    names.push(entry.name)
                    if (entry.name === 'link') {
                        assert.ok(entry.isSymbolicLink())
                    } else if (entry.name === 'apples') {
                        assert.ok(entry.isFile())
                    }
                }
                names.sort()
                assert.deepStrictEqual(names, ['apples', 'link'])

                revertPatches()
            }
        )
    })

    await it('can async iterate opendir link out of root', async () => {
        await withFixtures(
            {
                a: { apples: 'contents' },
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)
                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([path.join(fixturesDir, 'a')])

                const dir = await util.promisify(fs.opendir)(
                    path.join(fixturesDir, 'a')
                )
                const names = []
                for await (const entry of dir) {
                    names.push(entry.name)
                    if (entry.name === 'link') {
                        assert.ok(!entry.isSymbolicLink())
                        assert.ok(entry.isFile())
                    } else if (entry.name === 'apples') {
                        assert.ok(entry.isFile())
                    }
                }
                names.sort()
                assert.deepStrictEqual(names, ['apples', 'link'])

                revertPatches()
            }
        )
    })

    await it('can opendir dirent in a sandbox', async () => {
        await withFixtures(
            {
                sandbox: {},
                execroot: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from execroot/link2 to execroot/file
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'file'),
                    path.join(fixturesDir, 'execroot', 'link2')
                )
                // create symlink from execroot/link to execroot/link2
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'link2'),
                    path.join(fixturesDir, 'execroot', 'link')
                )

                // create sandbox; relative symlinks are maintained (assume Bazel 6 with allow unresolved symlinks)
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'file'),
                    path.join(fixturesDir, 'sandbox', 'file')
                )
                fs.symlinkSync(
                    path.join(fixturesDir, 'sandbox', 'file'),
                    path.join(fixturesDir, 'sandbox', 'link2')
                )
                fs.symlinkSync(
                    path.join(fixturesDir, 'sandbox', 'link2'),
                    path.join(fixturesDir, 'sandbox', 'link')
                )

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])

                let dir
                dir = await util.promisify(fs.opendir)(
                    path.join(fixturesDir, 'sandbox')
                )
                const entry1 = await dir.read()
                const entry2 = await new Promise((resolve, reject) => {
                    try {
                        resolve(dir.readSync())
                    } catch (err) {
                        reject(err)
                    }
                })
                const entry3 = dir.readSync()
                const empty = await dir.read()

                let names = [entry1.name, entry2.name, entry3.name]
                names.sort()
                assert.deepStrictEqual(names, ['file', 'link', 'link2'])

                assert.ok(
                    entry1.name === 'file'
                        ? !entry1.isSymbolicLink()
                        : entry1.isSymbolicLink()
                )
                assert.ok(
                    entry2.name === 'file'
                        ? !entry2.isSymbolicLink()
                        : entry2.isSymbolicLink()
                )
                assert.ok(
                    entry3.name === 'file'
                        ? !entry3.isSymbolicLink()
                        : entry3.isSymbolicLink()
                )

                assert.ok(!empty, 'last read should be falsey')

                revertPatches()
            }
        )
    })
})
