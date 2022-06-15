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

import { Stats } from 'fs'
import * as path from 'path'
import * as util from 'util'

// windows cant find the right types
type Dir = any
type Dirent = any

// using require here on purpose so we can override methods with any
// also even though imports are mutable in typescript the cognitive dissonance is too high because
// es modules
const _fs = require('fs')

const isWindows = process.platform === 'win32'

export const patcher = (fs: any = _fs, roots: string[]) => {
    fs = fs || _fs
    roots = roots || []
    roots = roots.filter((root) => fs.existsSync(root))
    if (!roots.length) {
        if (process.env.VERBOSE_LOGS) {
            console.error(
                'fs patcher called without any valid root paths ' + __filename
            )
        }
        return
    }

    const origLstat = fs.lstat.bind(fs)
    const origLstatSync = fs.lstatSync.bind(fs)

    const origReaddir = fs.readdir.bind(fs)
    const origReaddirSync = fs.readdirSync.bind(fs)

    const origReadlink = fs.readlink.bind(fs)
    const origReadlinkSync = fs.readlinkSync.bind(fs)

    const origRealpath = fs.realpath.bind(fs)
    const origRealpathNative = fs.realpath.native
    const origRealpathSync = fs.realpathSync.bind(fs)
    const origRealpathSyncNative = fs.realpathSync.native

    const isEscape = escapeFunction(roots)

    const logged: { [k: string]: boolean } = {}

    // =========================================================================
    // fs.lstat
    // =========================================================================

    fs.lstat = (...args: any[]) => {
        const ekey = new Error('').stack || ''
        if (!logged[ekey]) {
            logged[ekey] = true
        }

        let cb = args.length > 1 ? args[args.length - 1] : undefined
        // preserve error when calling function without required callback.
        if (cb) {
            cb = once(cb)
            args[args.length - 1] = (err: Error, stats: Stats) => {
                if (err) return cb(err)

                if (!stats.isSymbolicLink()) {
                    // the file is not a symbolic link so there is nothing more to do
                    return cb(null, stats)
                }

                // the file is a symbolic link; lets do a readlink and check where it points to
                const linkPath = path.resolve(args[0])
                return origReadlink(
                    linkPath,
                    (err: Error & { code: string }, str: string) => {
                        if (err) {
                            if (err.code === 'ENOENT') {
                                return cb(null, stats)
                            } else {
                                // some other file system related error.
                                return cb(err)
                            }
                        }

                        const linkTarget = path.resolve(
                            path.dirname(linkPath),
                            str
                        )

                        if (isEscape(linkPath, linkTarget)) {
                            // if the linkTarget is an escape, then return the lstat of the
                            // target instead
                            return origLstat(
                                linkTarget,
                                (
                                    err: Error & { code: string },
                                    linkTargetStats: Stats
                                ) => {
                                    if (err) {
                                        if (err.code === 'ENOENT') {
                                            return cb(null, stats)
                                        } else {
                                            // some other file system related error.
                                            return cb(err)
                                        }
                                    }

                                    // return the lstat of the linkTarget
                                    cb(null, linkTargetStats)
                                }
                            )
                        }

                        // its a symlink and its inside of the root.
                        cb(null, stats)
                    }
                )
            }
        }
        origLstat(...args)
    }

    fs.lstatSync = (...args: any[]) => {
        const stats = origLstatSync(...args)

        if (!stats.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return stats
        }

        const linkPath = path.resolve(args[0])
        let linkTarget: string
        try {
            linkTarget = path.resolve(
                path.dirname(args[0]),
                origReadlinkSync(linkPath)
            )
        } catch (e) {
            if (e.code === 'ENOENT') {
                return stats
            }
            throw e
        }

        if (isEscape(linkPath, linkTarget)) {
            // if the linkTarget is an escape, then return the lstat of the
            // target instead
            try {
                return origLstatSync(linkTarget, ...args.slice(1))
            } catch (e) {
                if (e.code === 'ENOENT') {
                    return stats
                }
                throw e
            }
        }

        return stats
    }

    // =========================================================================
    // fs.realpath
    // =========================================================================

    fs.realpath = (...args: any[]) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined
        if (cb) {
            cb = once(cb)
            args[args.length - 1] = (err: Error, str: string) => {
                if (err) return cb(err)
                const escapedRoot = isEscape(args[0], str)
                if (escapedRoot) {
                    // we've escaped a root; lets the file we've resolved is a symlink and see if our
                    // realpath can be mapped back to the root
                    let linkTarget: string
                    try {
                        linkTarget = path.resolve(
                            path.dirname(args[0]),
                            origReadlinkSync(args[0])
                        )
                    } catch (e) {
                        if (e.code === 'EINVAL') {
                            // the path was not a symlink; just return the resolved path in that case
                            return cb(null, str)
                        }
                        if (isWindows) {
                            // windows has a harder time with readlink if the path is
                            // through a junction; just return the realpath in this case
                            return cb(null, str)
                        }
                        throw e
                    }

                    const realPathRoot = path.resolve(
                        args[0],
                        path.relative(linkTarget, str)
                    )
                    if (!isEscape(args[0], realPathRoot, [escapedRoot])) {
                        // this realpath can be mapped back to a relative equivalent in the escaped root; return that instead
                        return cb(null, realPathRoot)
                    } else {
                        // the realpath has no relative equivalent within the root; return the actual realpath
                        return cb(null, str)
                    }
                } else {
                    return cb(null, str)
                }
            }
        }
        origRealpath(...args)
    }

    fs.realpath.native = (...args) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined
        if (cb) {
            cb = once(cb)
            args[args.length - 1] = (err: Error, str: string) => {
                if (err) return cb(err)
                const escapedRoot = isEscape(args[0], str)
                if (escapedRoot) {
                    // we've escaped a root; lets the file we've resolved is a symlink and see if our
                    // realpath can be mapped back to the root
                    let linkTarget: string
                    try {
                        linkTarget = path.resolve(
                            path.dirname(args[0]),
                            origReadlinkSync(args[0])
                        )
                    } catch (e) {
                        if (e.code === 'EINVAL') {
                            // the path was not a symlink; just return the resolved path in that case
                            return cb(null, str)
                        }
                        if (isWindows) {
                            // windows has a harder time with readlink if the path is
                            // through a junction; just return the realpath in this case
                            return cb(null, str)
                        }
                        throw e
                    }

                    const realPathRoot = path.resolve(
                        args[0],
                        path.relative(linkTarget, str)
                    )
                    if (!isEscape(args[0], realPathRoot, [escapedRoot])) {
                        // this realpath can be mapped back to a relative equivalent in the escaped root; return that instead
                        return cb(null, realPathRoot)
                    } else {
                        // the realpath has no relative equivalent within the root; return the actual realpath
                        return cb(null, str)
                    }
                } else {
                    return cb(null, str)
                }
            }
        }
        origRealpathNative(...args)
    }

    fs.realpathSync = (...args: any[]) => {
        const str = origRealpathSync(...args)
        const escapedRoot = isEscape(args[0], str)
        if (escapedRoot) {
            // we've escaped a root; lets the file we've resolved is a symlink and see if our
            // realpath can be mapped back to the root
            let linkTarget: string
            try {
                linkTarget = path.resolve(
                    path.dirname(args[0]),
                    origReadlinkSync(args[0])
                )
            } catch (e) {
                if (e.code === 'EINVAL') {
                    // the path was not a symlink; just return the resolved path in that case
                    return str
                }
                if (isWindows) {
                    // windows has a harder time with readlink if the path is
                    // through a junction; just return the realpath in this case
                    return str
                }
                throw e
            }

            const realPathRoot = path.resolve(
                args[0],
                path.relative(linkTarget, str)
            )
            if (!isEscape(args[0], realPathRoot, [escapedRoot])) {
                // this realpath can be mapped back to a relative equivalent in the escaped root; return that instead
                return realPathRoot
            } else {
                // the realpath has no relative equivalent within the root; return the actual realpath
                return str
            }
        }
        return str
    }

    fs.realpathSync.native = (...args: any[]) => {
        const str = origRealpathSyncNative(...args)
        const escapedRoot = isEscape(args[0], str)
        if (escapedRoot) {
            // we've escaped a root; lets the file we've resolved is a symlink and see if our
            // realpath can be mapped back to the root
            let linkTarget: string
            try {
                linkTarget = path.resolve(
                    path.dirname(args[0]),
                    origReadlinkSync(args[0])
                )
            } catch (e) {
                if (e.code === 'EINVAL') {
                    // the path was not a symlink; just return the resolved path in that case
                    return str
                }
                if (isWindows) {
                    // windows has a harder time with readlink if the path is
                    // through a junction; just return the realpath in this case
                    return str
                }
                throw e
            }

            const realPathRoot = path.resolve(
                args[0],
                path.relative(linkTarget, str)
            )
            if (!isEscape(args[0], realPathRoot, [escapedRoot])) {
                // this realpath can be mapped back to a relative equivalent in the escaped root; return that instead
                return realPathRoot
            } else {
                // the realpath has no relative equivalent within the root; return the actual realpath
                return str
            }
        }
        return str
    }

    // =========================================================================
    // fs.readlink
    // =========================================================================

    fs.readlink = (...args: any[]) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined
        if (cb) {
            cb = once(cb)
            args[args.length - 1] = (err: Error, str: string) => {
                args[0] = path.resolve(args[0])
                if (str) str = path.resolve(path.dirname(args[0]), str)

                if (err) return cb(err)

                if (isEscape(args[0], str)) {
                    // if we've escaped then call readlink on the escaped file
                    return origReadlink(str, ...args.slice(1))
                }
                cb(null, str)
            }
        }
        origReadlink(...args)
    }

    fs.readlinkSync = (...args: any[]) => {
        args[0] = path.resolve(args[0])

        const str = path.resolve(
            path.dirname(args[0]),
            origReadlinkSync(...args)
        )
        if (isEscape(args[0], str)) {
            // if we've escaped then call readlink on the escaped file
            return origReadlinkSync(str, ...args.slice(1))
        }
        return str
    }

    // =========================================================================
    // fs.readdir
    // =========================================================================

    fs.readdir = (...args: any[]) => {
        const p = path.resolve(args[0])

        let cb = args[args.length - 1]
        if (typeof cb !== 'function') {
            // this will likely throw callback required error.
            return origReaddir(...args)
        }

        cb = once(cb)
        args[args.length - 1] = (err: Error, result: Dirent[]) => {
            if (err) return cb(err)
            // user requested withFileTypes
            if (result[0] && result[0].isSymbolicLink) {
                Promise.all(result.map((v: Dirent) => handleDirent(p, v)))
                    .then(() => {
                        cb(null, result)
                    })
                    .catch((err) => {
                        cb(err)
                    })
            } else {
                // string array return for readdir.
                cb(null, result)
            }
        }

        origReaddir(...args)
    }

    fs.readdirSync = (...args: any[]) => {
        const res = origReaddirSync(...args)
        const p = path.resolve(args[0])
        res.forEach((v: Dirent | any) => {
            handleDirentSync(p, v)
        })
        return res
    }

    // =========================================================================
    // fs.opendir
    // =========================================================================

    if (fs.opendir) {
        const origOpendir = fs.opendir.bind(fs)
        fs.opendir = (...args: any[]) => {
            let cb = args[args.length - 1]
            // if this is not a function opendir should throw an error.
            // we call it so we don't have to throw a mock
            if (typeof cb === 'function') {
                cb = once(cb)
                args[args.length - 1] = async (err: Error, dir: Dir) => {
                    try {
                        cb(null, await handleDir(dir))
                    } catch (e) {
                        cb(e)
                    }
                }
                origOpendir(...args)
            } else {
                return origOpendir(...args).then((dir: Dir) => {
                    return handleDir(dir)
                })
            }
        }
    }

    // =========================================================================
    // fs.promises
    // =========================================================================

    /**
     * patch fs.promises here.
     *
     * this requires a light touch because if we trigger the getter on older nodejs versions
     * it will log an experimental warning to stderr
     *
     * `(node:62945) ExperimentalWarning: The fs.promises API is experimental`
     *
     * this api is available as experimental without a flag so users can access it at any time.
     */
    const promisePropertyDescriptor = Object.getOwnPropertyDescriptor(
        fs,
        'promises'
    )
    if (promisePropertyDescriptor) {
        const promises: any = {}
        promises.lstat = util.promisify(fs.lstat)
        // NOTE: node core uses the newer realpath function fs.promises.native instead of fs.realPath
        promises.realpath = util.promisify(fs.realpath.native)
        promises.readlink = util.promisify(fs.readlink)
        promises.readdir = util.promisify(fs.readdir)
        if (fs.opendir) promises.opendir = util.promisify(fs.opendir)
        // handle experimental api warnings.
        // only applies to version of node where promises is a getter property.
        if (promisePropertyDescriptor.get) {
            const oldGetter = promisePropertyDescriptor.get.bind(fs)
            const cachedPromises = {}

            promisePropertyDescriptor.get = () => {
                const _promises = oldGetter()
                Object.assign(cachedPromises, _promises, promises)
                return cachedPromises
            }
            Object.defineProperty(fs, 'promises', promisePropertyDescriptor)
        } else {
            // api can be patched directly
            Object.assign(fs.promises, promises)
        }
    }

    // =========================================================================
    // helper functions for dirs
    // =========================================================================

    async function handleDir(dir: Dir) {
        const p = path.resolve(dir.path)
        const origIterator = dir[Symbol.asyncIterator].bind(dir)
        const origRead: any = dir.read.bind(dir)

        dir[Symbol.asyncIterator] = async function* () {
            for await (const entry of origIterator()) {
                await handleDirent(p, entry)
                yield entry
            }
        }
        ;(dir.read as any) = async (...args: any[]) => {
            if (typeof args[args.length - 1] === 'function') {
                const cb = args[args.length - 1]
                args[args.length - 1] = async (err: Error, entry: Dirent) => {
                    cb(err, entry ? await handleDirent(p, entry) : null)
                }
                origRead(...args)
            } else {
                const entry = await origRead(...args)
                if (entry) {
                    await handleDirent(p, entry)
                }
                return entry
            }
        }
        const origReadSync: any = dir.readSync.bind(dir)
        ;(dir.readSync as any) = () => {
            return handleDirentSync(p, origReadSync())
        }

        return dir
    }

    function handleDirent(p: string, v: Dirent): Promise<Dirent> {
        return new Promise((resolve, reject) => {
            if (!v.isSymbolicLink()) {
                return resolve(v)
            }
            const linkPath = path.join(p, v.name)
            origReadlink(linkPath, (err: Error, target: string) => {
                if (err) {
                    return reject(err)
                }

                if (!isEscape(linkPath, path.resolve(target))) {
                    return resolve(v)
                }

                fs.stat(
                    target,
                    (err: Error & { code: string }, stat: Stats) => {
                        if (err) {
                            if (err.code === 'ENOENT') {
                                // this is a broken symlink
                                // even though this broken symlink points outside of the root
                                // we'll return it.
                                // the alternative choice here is to omit it from the directory listing altogether
                                // this would add complexity because readdir output would be different than readdir
                                // withFileTypes unless readdir was changed to match. if readdir was changed to match
                                // it's performance would be greatly impacted because we would always have to use the
                                // withFileTypes version which is slower.
                                return resolve(v)
                            }
                            // transient fs related error. busy etc.
                            return reject(err)
                        }

                        // add all stat is methods to Dirent instances with their result.
                        v.isSymbolicLink = () =>
                            origLstatSync(target).isSymbolicLink
                        patchDirent(v, stat)
                        resolve(v)
                    }
                )
            })
        })
    }

    function handleDirentSync(p: string, v: Dirent | null) {
        if (v && v.isSymbolicLink) {
            if (v.isSymbolicLink()) {
                // any errors thrown here are valid. things like transient fs errors
                const target = path.resolve(
                    p,
                    origReadlinkSync(path.join(p, v.name))
                )
                if (isEscape(path.join(p, v.name), target)) {
                    // Dirent exposes file type so if we want to hide that this is a link
                    // we need to find out if it's a file or directory.
                    v.isSymbolicLink = () =>
                        origLstatSync(target).isSymbolicLink
                    const stat: Stats | any = fs.statSync(target)
                    // add all stat is methods to Dirent instances with their result.
                    patchDirent(v, stat)
                }
            }
        }
    }
}

// =========================================================================
// generic helper functions
// =========================================================================

export function isSubPath(parent, child) {
    return !path.relative(parent, child).startsWith('..')
}

export const escapeFunction = (_roots: string[]) => {
    // ensure roots are always absolute
    _roots = _roots.map((root) => path.resolve(root))
    function _isEscape(
        linkPath: string,
        linkTarget: string,
        roots = _roots
    ): false | string {
        // linkPath is the path of the symlink file itself
        // linkTarget is a path that the symlink points to one or more hops away

        if (!path.isAbsolute(linkPath)) {
            linkPath = path.resolve(linkPath)
        }

        if (!path.isAbsolute(linkTarget)) {
            linkTarget = path.resolve(linkTarget)
        }

        let escapedRoot = undefined
        for (const root of roots) {
            // If the link is in the root check if the realPath has escaped
            if (isSubPath(root, linkPath) || linkPath == root) {
                if (!isSubPath(root, linkTarget) && linkTarget != root) {
                    if (!escapedRoot || escapedRoot.length < root.length) {
                        // if escaping multiple roots then choose the longest one
                        escapedRoot = root
                    }
                }
            }
        }
        if (escapedRoot) {
            return escapedRoot
        }

        return false
    }

    return _isEscape
}

function once<T>(fn: (...args: unknown[]) => T) {
    let called = false

    return (...args: unknown[]) => {
        if (called) return
        called = true

        let err: Error | false = false
        try {
            fn(...args)
        } catch (_e) {
            err = _e
        }

        // blow the stack to make sure this doesn't fall into any unresolved promise contexts
        if (err) {
            setImmediate(() => {
                throw err
            })
        }
    }
}

function patchDirent(dirent: Dirent | any, stat: Stats | any) {
    // add all stat is methods to Dirent instances with their result.
    for (const i in stat) {
        if (i.indexOf('is') === 0 && typeof stat[i] === 'function') {
            //
            const result = stat[i]()
            if (result) dirent[i] = () => true
            else dirent[i] = () => false
        }
    }
}
