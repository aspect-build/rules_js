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
import { deepStrictEqual, ok } from 'assert'
import * as fs from 'fs'
import { withFixtures } from 'inline-fixtures'
import * as path from 'path'
import * as util from 'util'

import { patcher } from '../../node-patches/src/fs'

// We don't want to bring jest into this repo so we just fake the describe and it functions here
async function describe(_, fn) {
    await fn()
}
async function it(_, fn) {
    await fn()
}

describe('testing readdir', async () => {
    await it('can readdir dirent in root', async () => {
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

                const patchedFs = Object.assign({}, fs)
                patchedFs.promises = Object.assign({}, fs.promises)
                patcher(patchedFs, [fixturesDir])

                let dirents = patchedFs.readdirSync(
                    path.join(fixturesDir, 'a'),
                    {
                        withFileTypes: true,
                    }
                )
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(dirents[1].isSymbolicLink())

                dirents = await util.promisify(patchedFs.readdir)(
                    path.join(fixturesDir, 'a'),
                    { withFileTypes: true }
                )
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(dirents[1].isSymbolicLink())

                dirents = await patchedFs.promises.readdir(
                    path.join(fixturesDir, 'a'),
                    { withFileTypes: true }
                )
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(dirents[1].isSymbolicLink())
            }
        )
    })

    await it('can readdir link dirents as files out of root', async () => {
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

                const patchedFs = Object.assign({}, fs)
                patchedFs.promises = Object.assign({}, fs.promises)
                patcher(patchedFs, [path.join(fixturesDir, 'a')])

                console.error('FOO')
                console.error(patchedFs.readdirSync)
                let dirents = patchedFs.readdirSync(
                    path.join(fixturesDir, 'a'),
                    {
                        withFileTypes: true,
                    }
                )
                console.error('BAR')
                console.log(dirents)
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(!dirents[1].isSymbolicLink())
                ok(dirents[1].isFile())

                console.error('FOO')
                dirents = await util.promisify(patchedFs.readdir)(
                    path.join(fixturesDir, 'a'),
                    { withFileTypes: true }
                )
                console.error('BAR')
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(!dirents[1].isSymbolicLink())
                ok(dirents[1].isFile())

                dirents = await patchedFs.promises.readdir(
                    path.join(fixturesDir, 'a'),
                    { withFileTypes: true }
                )
                deepStrictEqual(dirents[0].name, 'apples')
                deepStrictEqual(dirents[1].name, 'link')
                ok(dirents[0].isFile())
                ok(!dirents[1].isSymbolicLink())
                ok(dirents[1].isFile())
            }
        )
    })
})
