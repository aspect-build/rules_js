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

describe('testing realpath', async () => {
    await it('can handle empty, dot, undefined & null values', async () => {
        const revertPatches = patcher([process.cwd()])

        // ---------------------------------------------------------------------
        // empty string

        assert.deepStrictEqual(
            fs.realpathSync(''),
            process.cwd(),
            'should handle an empty string'
        )

        assert.throws(() => {
            fs.realpathSync.native('')
        }, 'should throw if empty string is passed')

        assert.deepStrictEqual(
            await util.promisify(fs.realpath)(''),
            process.cwd(),
            'should handle an empty string'
        )

        let thrown
        try {
            await util.promisify(fs.realpath.native)('')
        } catch (e) {
            thrown = e
        } finally {
            if (!thrown) assert.fail('should throw if empty string is passed')
        }

        // ---------------------------------------------------------------------
        // '.'

        assert.deepStrictEqual(
            fs.realpathSync('.'),
            process.cwd(),
            "should handle '.'"
        )

        assert.deepStrictEqual(
            fs.realpathSync.native('.'),
            process.cwd(),
            "should handle '.'"
        )

        assert.deepStrictEqual(
            await util.promisify(fs.realpath)('.'),
            process.cwd(),
            "should handle '.'"
        )

        assert.deepStrictEqual(
            await util.promisify(fs.realpath.native)('.'),
            process.cwd(),
            "should handle '.'"
        )

        // ---------------------------------------------------------------------
        // undefined

        assert.throws(() => {
            fs.realpathSync(undefined)
        }, 'should throw if undefined is passed')

        assert.throws(() => {
            fs.realpathSync.native(undefined)
        }, 'should throw if undefined is passed')

        thrown = undefined
        try {
            await util.promisify(fs.realpath)(undefined)
        } catch (e) {
            thrown = e
        } finally {
            if (!thrown) assert.fail('should throw if undefined is passed')
        }

        thrown = undefined
        try {
            await util.promisify(fs.realpath.native)(undefined)
        } catch (e) {
            thrown = e
        } finally {
            if (!thrown) assert.fail('should throw if undefined is passed')
        }

        // ---------------------------------------------------------------------
        // null

        assert.throws(() => {
            fs.realpathSync(null)
        }, 'should throw if null is passed')

        assert.throws(() => {
            fs.realpathSync.native(null)
        }, 'should throw if null is passed')

        thrown = undefined
        try {
            await util.promisify(fs.realpath)(null)
        } catch (e) {
            thrown = e
        } finally {
            if (!thrown) assert.fail('should throw if null is passed')
        }

        thrown = undefined
        try {
            await util.promisify(fs.realpath.native)(null)
        } catch (e) {
            thrown = e
        } finally {
            if (!thrown) assert.fail('should throw if null is passed')
        }

        revertPatches()
    })

    await it('can resolve symlink in root', async () => {
        await withFixtures(
            {
                a: {},
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                // on mac, inside of bazel, the fixtures dir returned here is not realpath-ed.
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([path.join(fixturesDir)])
                const linkPath = path.join(
                    fs.realpathSync(fixturesDir),
                    'a',
                    'link'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(linkPath),
                    path.join(fixturesDir, 'b', 'file'),
                    'SYNC: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(linkPath),
                    path.join(fixturesDir, 'b', 'file'),
                    'SYNC.native: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(linkPath),
                    path.join(fixturesDir, 'b', 'file'),
                    'CB: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(linkPath),
                    path.join(fixturesDir, 'b', 'file'),
                    'CB: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(linkPath),
                    path.join(fixturesDir, 'b', 'file'),
                    'Promise: should resolve the symlink the same because its within root'
                )

                revertPatches()
            }
        )
    })

    await it('can resolve a real file and directory in root', async () => {
        await withFixtures(
            {
                a: { file: 'contents' },
            },
            async (fixturesDir) => {
                // on mac, inside of bazel, the fixtures dir returned here is not realpath-ed.
                fixturesDir = fs.realpathSync(fixturesDir)

                const revertPatches = patcher([path.join(fixturesDir)])
                const filePath = path.join(
                    fs.realpathSync(fixturesDir),
                    'a',
                    'file'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(filePath),
                    filePath,
                    'SYNC: should resolve the a real file within the root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(filePath),
                    filePath,
                    'SYNC.native: should resolve the a real file within the root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(filePath),
                    filePath,
                    'CB: should resolve the a real file within the root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(filePath),
                    filePath,
                    'CB: should resolve the a real file within the root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(filePath),
                    filePath,
                    'Promise: should resolve the a real file within the root'
                )

                const directoryPath = path.join(
                    fs.realpathSync(fixturesDir),
                    'a'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(directoryPath),
                    directoryPath,
                    'SYNC: should resolve the a real directory within the root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(directoryPath),
                    directoryPath,
                    'SYNC.native: should resolve the a real directory within the root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(directoryPath),
                    directoryPath,
                    'CB: should resolve the a real directory within the root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(directoryPath),
                    directoryPath,
                    'CB: should resolve the a real directory within the root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(directoryPath),
                    directoryPath,
                    'Promise: should resolve the a real directory within the root'
                )

                revertPatches()
            }
        )
    })

    await it("doesn't resolve as symlink outside of root", async () => {
        await withFixtures(
            {
                a: {},
                b: { file: 'contents' },
            },
            async (fixturesDir) => {
                // ensure realpath.
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from a to b
                fs.symlinkSync(
                    path.join(fixturesDir, 'b', 'file'),
                    path.join(fixturesDir, 'a', 'link')
                )

                const revertPatches = patcher([path.join(fixturesDir, 'a')])
                const linkPath = path.join(
                    fs.realpathSync(fixturesDir),
                    'a',
                    'link'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(linkPath),
                    path.join(fixturesDir, 'a', 'link'),
                    'should pretend symlink is in the root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(new URL(`file://${linkPath}`)),
                    path.join(fixturesDir, 'a', 'link'),
                    'should pretend symlink is in the root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(linkPath),
                    path.join(fixturesDir, 'a', 'link'),
                    'should pretend symlink is in the root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(linkPath),
                    path.join(fixturesDir, 'a', 'link'),
                    'should pretend symlink is in the root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(new URL(`file://${linkPath}`)),
                    path.join(fixturesDir, 'a', 'link'),
                    'should pretend symlink is in the root'
                )

                revertPatches()
            }
        )
    })

    await it('can resolve a symlink to a non-existing path', async () => {
        await withFixtures(
            {
                sandbox: {},
                execroot: {},
                otherroot: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])

                let brokenLinkPath = path.join(
                    fixturesDir,
                    'sandbox',
                    'broken-link'
                )
                fs.symlinkSync(
                    path.join(fixturesDir, 'doesnt-exist'),
                    brokenLinkPath
                )

                assert.throws(
                    () => fs.realpathSync(brokenLinkPath),
                    'should throw because link is broken'
                )

                let thrown
                try {
                    await util.promisify(fs.realpath.native)(brokenLinkPath)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown)
                        assert.fail('should throw if empty string is passed')
                }

                try {
                    await fs.promises.realpath(brokenLinkPath)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown)
                        assert.fail('should throw if empty string is passed')
                }

                revertPatches()
            }
        )
    })

    await it('can resolve a symlink to a non-existing path after escaping', async () => {
        await withFixtures(
            {
                sandbox: {},
                execroot: {},
                otherroot: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                const nonSandboxedBrokenLink = path.join(
                    fixturesDir,
                    'broken-link'
                )

                fs.symlinkSync(
                    path.join(fixturesDir, 'doesnt-exist'),
                    nonSandboxedBrokenLink
                )

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])

                let sandboxedLinkToBrokenLink = path.join(
                    fixturesDir,
                    'sandbox',
                    'indirect-link'
                )
                fs.symlinkSync(
                    nonSandboxedBrokenLink,
                    sandboxedLinkToBrokenLink
                )

                assert.throws(
                    () => fs.realpathSync(sandboxedLinkToBrokenLink),
                    'should throw because link is broken'
                )

                let thrown
                try {
                    await util.promisify(fs.realpath.native)(
                        sandboxedLinkToBrokenLink
                    )
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown)
                        assert.fail('should throw if empty string is passed')
                }

                try {
                    await fs.promises.realpath(sandboxedLinkToBrokenLink)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown)
                        assert.fail('should throw if empty string is passed')
                }

                revertPatches()
            }
        )
    })

    await it('can resolve symlink to a symlink in the sandbox if there is no corresponding location in the sandbox but is a realpath outside', async () => {
        await withFixtures(
            {
                sandbox: {},
                execroot: {},
                otherroot: { file: 'contents' },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from execroot/link to otherroot/file
                fs.symlinkSync(
                    path.join(fixturesDir, 'otherroot', 'file'),
                    path.join(fixturesDir, 'execroot', 'link')
                )

                // create sandbox
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'link'),
                    path.join(fixturesDir, 'sandbox', 'link')
                )

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])
                const linkPath = path.join(fixturesDir, 'sandbox', 'link')

                assert.deepStrictEqual(
                    fs.realpathSync(linkPath),
                    linkPath,
                    'SYNC: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(new URL(`file://${linkPath}`)),
                    linkPath,
                    'SYNC: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(linkPath),
                    linkPath,
                    'SYNC.native: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(new URL(`file://${linkPath}`)),
                    linkPath,
                    'SYNC.native: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(linkPath),
                    linkPath,
                    'CB: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(linkPath),
                    linkPath,
                    'CB: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(linkPath),
                    linkPath,
                    'Promise: should resolve the symlink the same because its within root'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(new URL(`file://${linkPath}`)),
                    linkPath,
                    'Promise: should resolve the symlink the same because its within root'
                )

                revertPatches()
            }
        )
    })

    await it('cant resolve symlink to a symlink in the sandbox if it is dangling outside of the sandbox', async () => {
        await withFixtures(
            {
                sandbox: {},
                execroot: {},
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from execroot/link to otherroot/file
                fs.symlinkSync(
                    path.join(fixturesDir, 'otherroot', 'file'),
                    path.join(fixturesDir, 'execroot', 'link')
                )

                // create sandbox
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'link'),
                    path.join(fixturesDir, 'sandbox', 'link')
                )

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])
                const linkPath = path.join(fixturesDir, 'sandbox', 'link')

                assert.throws(() => {
                    fs.realpathSync(linkPath)
                }, "should throw because it's not a resolvable link")

                assert.throws(() => {
                    fs.realpathSync.native(linkPath)
                }, "should throw because it's not a resolvable link")

                let thrown
                try {
                    await util.promisify(fs.realpath)(linkPath)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown) assert.fail('must throw einval error')
                }

                thrown = undefined
                try {
                    await util.promisify(fs.realpath.native)(linkPath)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown) assert.fail('must throw einval error')
                }

                thrown = undefined
                try {
                    await fs.promises.realpath(linkPath)
                } catch (e) {
                    thrown = e
                } finally {
                    if (!thrown) assert.fail('must throw einval error')
                }

                revertPatches()
            }
        )
    })

    await it('can resolve a nested escaping symlinking within a non-escaping parent directory symlink', async () => {
        await withFixtures(
            {
                sandbox: {
                    node_modules: {},
                    package_store: { pkg: {} },
                },
                execroot: {
                    node_modules: {},
                    package_store: {
                        pkg: {
                            file: 'contents',
                        },
                    },
                },
            },
            async (fixturesDir) => {
                fixturesDir = fs.realpathSync(fixturesDir)

                // create symlink from execroot/node_modules/pkg to execroot/package_store/pkg
                fs.symlinkSync(
                    path.join(fixturesDir, 'execroot', 'package_store', 'pkg'),
                    path.join(fixturesDir, 'execroot', 'node_modules', 'pkg')
                )

                // create sandbox (with relative symlinks in place)
                fs.symlinkSync(
                    path.join(
                        fixturesDir,
                        'execroot',
                        'package_store',
                        'pkg',
                        'file'
                    ),
                    path.join(
                        fixturesDir,
                        'sandbox',
                        'package_store',
                        'pkg',
                        'file'
                    )
                )
                fs.symlinkSync(
                    path.join(fixturesDir, 'sandbox', 'package_store', 'pkg'),
                    path.join(fixturesDir, 'sandbox', 'node_modules', 'pkg')
                )

                const revertPatches = patcher([
                    path.join(fixturesDir, 'sandbox'),
                ])
                const linkPath = path.join(
                    fixturesDir,
                    'sandbox',
                    'node_modules',
                    'pkg',
                    'file'
                )
                const filePath = path.join(
                    fixturesDir,
                    'sandbox',
                    'package_store',
                    'pkg',
                    'file'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(linkPath),
                    filePath,
                    'SYNC: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(linkPath),
                    filePath,
                    'SYNC.native: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(linkPath),
                    filePath,
                    'CB: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(linkPath),
                    filePath,
                    'CB: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(linkPath),
                    filePath,
                    'Promise: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                const linkPath2 = path.join(
                    fixturesDir,
                    'sandbox',
                    'node_modules',
                    'pkg'
                )
                const filePath2 = path.join(
                    fixturesDir,
                    'sandbox',
                    'package_store',
                    'pkg'
                )

                assert.deepStrictEqual(
                    fs.realpathSync(linkPath2),
                    filePath2,
                    'SYNC: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    fs.realpathSync.native(linkPath2),
                    filePath2,
                    'SYNC.native: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath)(linkPath2),
                    filePath2,
                    'CB: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await util.promisify(fs.realpath.native)(linkPath2),
                    filePath2,
                    'CB: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                assert.deepStrictEqual(
                    await fs.promises.realpath(linkPath2),
                    filePath2,
                    'Promise: should resolve the nested escaping symlinking within a non-escaping parent directory symlink'
                )

                revertPatches()
            }
        )
    })

    await it('includes parent calls in stack traces', async function realpathStackTest1() {
        let err
        try {
            fs.realpathSync(null)
        } catch (e) {
            err = e
        } finally {
            if (!err) assert.fail('realpathSync should fail on invalid path')
            if (!err.stack.includes('realpathStackTest1'))
                assert.fail(
                    `realpathSync error stack should contain calling method: ${err.stack}`
                )
        }
    })
})
