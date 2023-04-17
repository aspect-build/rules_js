// Generated by //js/private/node-patches_legacy:compile
"use strict";
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
var __asyncValues = (this && this.__asyncValues) || function (o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i);
    function verb(n) { i[n] = o[n] && function (v) { return new Promise(function (resolve, reject) { v = o[n](v), settle(resolve, reject, v.done, v.value); }); }; }
    function settle(resolve, reject, d, v) { Promise.resolve(v).then(function(v) { resolve({ value: v, done: d }); }, reject); }
};
var __await = (this && this.__await) || function (v) { return this instanceof __await ? (this.v = v, this) : new __await(v); }
var __asyncGenerator = (this && this.__asyncGenerator) || function (thisArg, _arguments, generator) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var g = generator.apply(thisArg, _arguments || []), i, q = [];
    return i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i;
    function verb(n) { if (g[n]) i[n] = function (v) { return new Promise(function (a, b) { q.push([n, v, a, b]) > 1 || resume(n, v); }); }; }
    function resume(n, v) { try { step(g[n](v)); } catch (e) { settle(q[0][3], e); } }
    function step(r) { r.value instanceof __await ? Promise.resolve(r.value.v).then(fulfill, reject) : settle(q[0][2], r); }
    function fulfill(value) { resume("next", value); }
    function reject(value) { resume("throw", value); }
    function settle(f, v) { if (f(v), q.shift(), q.length) resume(q[0][0], q[0][1]); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.escapeFunction = exports.isSubPath = exports.patcher = void 0;
const path = require("path");
const util = require("util");
// using require here on purpose so we can override methods with any
// also even though imports are mutable in typescript the cognitive dissonance is too high because
// es modules
const _fs = require('fs');
const HOP_NON_LINK = Symbol.for('HOP NON LINK');
const HOP_NOT_FOUND = Symbol.for('HOP NOT FOUND');
const patcher = (fs = _fs, roots) => {
    fs = fs || _fs;
    // Make the original version of the library available for when access to the
    // unguarded file system is necessary, such as the esbuild plugin that
    // protects against sandbox escaping that occurs through module resolution
    // in the Go binary. See
    // https://github.com/aspect-build/rules_esbuild/issues/58.
    fs._unpatched = Object.assign({}, fs);
    roots = roots || [];
    roots = roots.filter((root) => fs.existsSync(root));
    if (!roots.length) {
        if (process.env.VERBOSE_LOGS) {
            console.error('fs patcher called without any valid root paths ' + __filename);
        }
        return;
    }
    const origLstat = fs.lstat.bind(fs);
    const origLstatSync = fs.lstatSync.bind(fs);
    const origReaddir = fs.readdir.bind(fs);
    const origReaddirSync = fs.readdirSync.bind(fs);
    const origReadlink = fs.readlink.bind(fs);
    const origReadlinkSync = fs.readlinkSync.bind(fs);
    const origRealpath = fs.realpath.bind(fs);
    const origRealpathNative = fs.realpath.native;
    const origRealpathSync = fs.realpathSync.bind(fs);
    const origRealpathSyncNative = fs.realpathSync.native;
    const { canEscape, isEscape } = escapeFunction(roots);
    // =========================================================================
    // fs.lstat
    // =========================================================================
    fs.lstat = (...args) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined;
        // preserve error when calling function without required callback
        if (!cb) {
            return origLstat(...args);
        }
        cb = once(cb);
        // override the callback
        args[args.length - 1] = (err, stats) => {
            if (err)
                return cb(err);
            if (!stats.isSymbolicLink()) {
                // the file is not a symbolic link so there is nothing more to do
                return cb(null, stats);
            }
            args[0] = path.resolve(args[0]);
            if (!canEscape(args[0])) {
                // the file can not escaped the sandbox so there is nothing more to do
                return cb(null, stats);
            }
            return guardedReadLink(args[0], (str) => {
                if (str != args[0]) {
                    // there are one or more hops within the guards so there is nothing more to do
                    return cb(null, stats);
                }
                // there are no hops so lets report the stats of the real file;
                // we can't use origRealPath here since that function calls lstat internally
                // which can result in an infinite loop
                return unguardedRealPath(args[0], (err, str) => {
                    if (err) {
                        if (err.code === 'ENOENT') {
                            // broken link so there is nothing more to do
                            return cb(null, stats);
                        }
                        return cb(err);
                    }
                    return origLstat(str, (err, str) => cb(err, str));
                });
            });
        };
        origLstat(...args);
    };
    fs.lstatSync = function lstatSync(...args) {
        const stats = origLstatSync(...args);
        if (!stats.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return stats;
        }
        args[0] = path.resolve(args[0]);
        if (!canEscape(args[0])) {
            // the file can not escaped the sandbox so there is nothing more to do
            return stats;
        }
        const guardedReadLink = guardedReadLinkSync(args[0]);
        if (guardedReadLink != args[0]) {
            // there are one or more hops within the guards so there is nothing more to do
            return stats;
        }
        try {
            // there are no hops so lets report the stats of the real file;
            // we can't use origRealPathSync here since that function calls lstat internally
            // which can result in an infinite loop
            return origLstatSync(unguardedRealPathSync(args[0]), ...args.slice(1));
        }
        catch (err) {
            if (err.code === 'ENOENT') {
                // broken link so there is nothing more to do
                return stats;
            }
            throw err;
        }
    };
    // =========================================================================
    // fs.realpath
    // =========================================================================
    fs.realpath = (...args) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined;
        // preserve error when calling function without required callback
        if (!cb) {
            return origRealpath(...args);
        }
        cb = once(cb);
        args[args.length - 1] = (err, str) => {
            if (err)
                return cb(err);
            const escapedRoot = isEscape(args[0], str);
            if (escapedRoot) {
                return guardedRealPath(args[0], (err, str) => cb(err, str), escapedRoot);
            }
            else {
                return cb(null, str);
            }
        };
        origRealpath(...args);
    };
    fs.realpath.native = (...args) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined;
        // preserve error when calling function without required callback
        if (!cb) {
            return origRealpathNative(...args);
        }
        cb = once(cb);
        args[args.length - 1] = (err, str) => {
            if (err)
                return cb(err);
            const escapedRoot = isEscape(args[0], str);
            if (escapedRoot) {
                return guardedRealPath(args[0], (err, str) => cb(err, str), escapedRoot);
            }
            else {
                return cb(null, str);
            }
        };
        origRealpathNative(...args);
    };
    fs.realpathSync = function realpathSync(...args) {
        const str = origRealpathSync(...args);
        const escapedRoot = isEscape(args[0], str);
        if (escapedRoot) {
            return guardedRealPathSync(args[0], escapedRoot);
        }
        return str;
    };
    fs.realpathSync.native = function native_realpathSync(...args) {
        const str = origRealpathSyncNative(...args);
        const escapedRoot = isEscape(args[0], str);
        if (escapedRoot) {
            return guardedRealPathSync(args[0], escapedRoot);
        }
        return str;
    };
    // =========================================================================
    // fs.readlink
    // =========================================================================
    fs.readlink = (...args) => {
        let cb = args.length > 1 ? args[args.length - 1] : undefined;
        // preserve error when calling function without required callback
        if (!cb) {
            return origReadlink(...args);
        }
        cb = once(cb);
        args[args.length - 1] = (err, str) => {
            if (err)
                return cb(err);
            const resolved = path.resolve(args[0]);
            str = path.resolve(path.dirname(resolved), str);
            const escapedRoot = isEscape(resolved, str);
            if (escapedRoot) {
                return nextHop(str, (next) => {
                    if (!next) {
                        if (next == undefined) {
                            // The escape from the root is not mappable back into the root; throw EINVAL
                            return cb(enoent('readlink', args[0]));
                        }
                        else {
                            // The escape from the root is not mappable back into the root; throw EINVAL
                            return cb(einval('readlink', args[0]));
                        }
                    }
                    next = path.resolve(path.dirname(resolved), path.relative(path.dirname(str), next));
                    if (next != resolved &&
                        !isEscape(resolved, next, [escapedRoot])) {
                        return cb(null, next);
                    }
                    // The escape from the root is not mappable back into the root; we must make
                    // this look like a real file so we call readlink on the realpath which we
                    // expect to return an error
                    return origRealpath(resolved, (err, str) => {
                        if (err)
                            return cb(err);
                        return origReadlink(str, (err, str) => cb(err, str));
                    });
                });
            }
            else {
                return cb(null, str);
            }
        };
        origReadlink(...args);
    };
    fs.readlinkSync = function readlinkSync(...args) {
        const resolved = path.resolve(args[0]);
        const str = path.resolve(path.dirname(resolved), origReadlinkSync(...args));
        const escapedRoot = isEscape(resolved, str);
        if (escapedRoot) {
            let next = nextHopSync(str);
            if (!next) {
                if (next == undefined) {
                    // The escape from the root is not mappable back into the root; throw EINVAL
                    throw enoent('readlink', args[0]);
                }
                else {
                    // The escape from the root is not mappable back into the root; throw EINVAL
                    throw einval('readlink', args[0]);
                }
            }
            next = path.resolve(path.dirname(resolved), path.relative(path.dirname(str), next));
            if (next != resolved && !isEscape(resolved, next, [escapedRoot])) {
                return next;
            }
            // The escape from the root is not mappable back into the root; throw EINVAL
            throw einval('readlink', args[0]);
        }
        return str;
    };
    // =========================================================================
    // fs.readdir
    // =========================================================================
    fs.readdir = (...args) => {
        const p = path.resolve(args[0]);
        let cb = args[args.length - 1];
        if (typeof cb !== 'function') {
            // this will likely throw callback required error.
            return origReaddir(...args);
        }
        cb = once(cb);
        args[args.length - 1] = (err, result) => {
            if (err)
                return cb(err);
            // user requested withFileTypes
            if (result[0] && result[0].isSymbolicLink) {
                Promise.all(result.map((v) => handleDirent(p, v)))
                    .then(() => {
                    cb(null, result);
                })
                    .catch((err) => {
                    cb(err);
                });
            }
            else {
                // string array return for readdir.
                cb(null, result);
            }
        };
        origReaddir(...args);
    };
    fs.readdirSync = function readdirSync(...args) {
        const res = origReaddirSync(...args);
        const p = path.resolve(args[0]);
        res.forEach((v) => {
            handleDirentSync(p, v);
        });
        return res;
    };
    // =========================================================================
    // fs.opendir
    // =========================================================================
    if (fs.opendir) {
        const origOpendir = fs.opendir.bind(fs);
        fs.opendir = (...args) => {
            let cb = args[args.length - 1];
            // if this is not a function opendir should throw an error.
            // we call it so we don't have to throw a mock
            if (typeof cb === 'function') {
                cb = once(cb);
                args[args.length - 1] = async (err, dir) => {
                    try {
                        cb(null, await handleDir(dir));
                    }
                    catch (err) {
                        cb(err);
                    }
                };
                origOpendir(...args);
            }
            else {
                return origOpendir(...args).then((dir) => {
                    return handleDir(dir);
                });
            }
        };
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
    const promisePropertyDescriptor = Object.getOwnPropertyDescriptor(fs, 'promises');
    if (promisePropertyDescriptor) {
        const promises = {};
        promises.lstat = util.promisify(fs.lstat);
        // NOTE: node core uses the newer realpath function fs.promises.native instead of fs.realPath
        promises.realpath = util.promisify(fs.realpath.native);
        promises.readlink = util.promisify(fs.readlink);
        promises.readdir = util.promisify(fs.readdir);
        if (fs.opendir)
            promises.opendir = util.promisify(fs.opendir);
        // handle experimental api warnings.
        // only applies to version of node where promises is a getter property.
        if (promisePropertyDescriptor.get) {
            const oldGetter = promisePropertyDescriptor.get.bind(fs);
            const cachedPromises = {};
            promisePropertyDescriptor.get = () => {
                const _promises = oldGetter();
                Object.assign(cachedPromises, _promises, promises);
                return cachedPromises;
            };
            Object.defineProperty(fs, 'promises', promisePropertyDescriptor);
        }
        else {
            // api can be patched directly
            Object.assign(fs.promises, promises);
        }
    }
    // =========================================================================
    // helper functions for dirs
    // =========================================================================
    async function handleDir(dir) {
        const p = path.resolve(dir.path);
        const origIterator = dir[Symbol.asyncIterator].bind(dir);
        const origRead = dir.read.bind(dir);
        dir[Symbol.asyncIterator] = function () {
            return __asyncGenerator(this, arguments, function* () {
                var _a, e_1, _b, _c;
                try {
                    for (var _d = true, _f = __asyncValues(origIterator()), _g; _g = yield __await(_f.next()), _a = _g.done, !_a;) {
                        _c = _g.value;
                        _d = false;
                        try {
                            const entry = _c;
                            yield __await(handleDirent(p, entry));
                            yield yield __await(entry);
                        }
                        finally {
                            _d = true;
                        }
                    }
                }
                catch (e_1_1) { e_1 = { error: e_1_1 }; }
                finally {
                    try {
                        if (!_d && !_a && (_b = _f.return)) yield __await(_b.call(_f));
                    }
                    finally { if (e_1) throw e_1.error; }
                }
            });
        };
        dir.read = async (...args) => {
            if (typeof args[args.length - 1] === 'function') {
                const cb = args[args.length - 1];
                args[args.length - 1] = async (err, entry) => {
                    cb(err, entry ? await handleDirent(p, entry) : null);
                };
                origRead(...args);
            }
            else {
                const entry = await origRead(...args);
                if (entry) {
                    await handleDirent(p, entry);
                }
                return entry;
            }
        };
        const origReadSync = dir.readSync.bind(dir);
        dir.readSync = () => {
            return handleDirentSync(p, origReadSync()); // intentionally sync for simplicity
        };
        return dir;
    }
    function handleDirent(p, v) {
        return new Promise((resolve, reject) => {
            if (!v.isSymbolicLink()) {
                return resolve(v);
            }
            const f = path.resolve(p, v.name);
            return guardedReadLink(f, (str) => {
                if (f != str) {
                    return resolve(v);
                }
                // There are no hops so we should hide the fact that the file is a symlink
                v.isSymbolicLink = () => false;
                origRealpath(f, (err, str) => {
                    if (err) {
                        throw err;
                    }
                    fs.stat(str, (err, stat) => {
                        if (err) {
                            throw err;
                        }
                        patchDirent(v, stat);
                        resolve(v);
                    });
                });
            });
        });
    }
    function handleDirentSync(p, v) {
        if (v && v.isSymbolicLink) {
            if (v.isSymbolicLink()) {
                const f = path.resolve(p, v.name);
                if (f == guardedReadLinkSync(f)) {
                    // There are no hops so we should hide the fact that the file is a symlink
                    v.isSymbolicLink = () => false;
                    const stat = fs.statSync(origRealpathSync(f));
                    patchDirent(v, stat);
                }
            }
        }
    }
    function nextHop(loc, cb) {
        let nested = [];
        let maybe = loc;
        let escapedHop = false;
        readHopLink(maybe, function readNextHop(link) {
            if (link === HOP_NOT_FOUND) {
                return cb(undefined);
            }
            if (link !== HOP_NON_LINK) {
                link = path.join(link, ...nested.reverse());
                if (!isEscape(loc, link)) {
                    return cb(link);
                }
                if (!escapedHop) {
                    escapedHop = link;
                }
            }
            const dirname = path.dirname(maybe);
            if (!dirname ||
                dirname == maybe ||
                dirname == '.' ||
                dirname == '/') {
                // not a link
                return cb(escapedHop);
            }
            nested.push(path.basename(maybe));
            maybe = dirname;
            readHopLink(maybe, readNextHop);
        });
    }
    const hopLinkCache = Object.create(null);
    function readHopLinkSync(p) {
        if (hopLinkCache[p]) {
            return hopLinkCache[p];
        }
        let link;
        try {
            link = origReadlinkSync(p);
            if (link) {
                if (!path.isAbsolute(link)) {
                    link = path.resolve(path.dirname(p), link);
                }
            }
            else {
                link = HOP_NON_LINK;
            }
        }
        catch (err) {
            if (err.code === 'ENOENT') {
                // file does not exist
                link = HOP_NOT_FOUND;
            }
            else {
                link = HOP_NON_LINK;
            }
        }
        hopLinkCache[p] = link;
        return link;
    }
    function readHopLink(p, cb) {
        if (hopLinkCache[p]) {
            return cb(hopLinkCache[p]);
        }
        origReadlink(p, (err, link) => {
            if (err) {
                let result;
                if (err.code === 'ENOENT') {
                    // file does not exist
                    result = HOP_NOT_FOUND;
                }
                else {
                    result = HOP_NON_LINK;
                }
                hopLinkCache[p] = result;
                return cb(result);
            }
            if (link === undefined) {
                hopLinkCache[p] = HOP_NON_LINK;
                return cb(HOP_NON_LINK);
            }
            if (!path.isAbsolute(link)) {
                link = path.resolve(path.dirname(p), link);
            }
            hopLinkCache[p] = link;
            cb(link);
        });
    }
    function nextHopSync(loc) {
        let nested = [];
        let maybe = loc;
        let escapedHop = false;
        for (;;) {
            let link = readHopLinkSync(maybe);
            if (link === HOP_NOT_FOUND) {
                return undefined;
            }
            if (link !== HOP_NON_LINK) {
                link = path.join(link, ...nested.reverse());
                if (!isEscape(loc, link)) {
                    return link;
                }
                if (!escapedHop) {
                    escapedHop = link;
                }
            }
            const dirname = path.dirname(maybe);
            if (!dirname ||
                dirname == maybe ||
                dirname == '.' ||
                dirname == '/') {
                // not a link
                return escapedHop;
            }
            nested.push(path.basename(maybe));
            maybe = dirname;
        }
    }
    function guardedReadLink(start, cb) {
        let loc = start;
        return nextHop(loc, (next) => {
            if (!next) {
                // we're no longer hopping but we haven't escaped;
                // something funky happened in the filesystem
                return cb(loc);
            }
            if (isEscape(loc, next)) {
                // this hop takes us out of the guard
                return nextHop(next, (next2) => {
                    if (!next2) {
                        // the chain is done
                        return cb(loc);
                    }
                    const maybe = path.resolve(path.dirname(loc), path.relative(path.dirname(next), next2));
                    if (!isEscape(loc, maybe)) {
                        // outside of the guard is a symlink but it is a relative link path
                        // we can map within the guard so return that
                        return cb(maybe);
                    }
                    // outside of the guard is a symlink that is not mappable inside the guard
                    return cb(loc);
                });
            }
            return cb(next);
        });
    }
    function guardedReadLinkSync(start) {
        let loc = start;
        let next = nextHopSync(loc);
        if (!next) {
            // we're no longer hopping but we haven't escaped;
            // something funky happened in the filesystem
            return loc;
        }
        if (isEscape(loc, next)) {
            // this hop takes us out of the guard
            const next2 = nextHopSync(next);
            if (!next2) {
                // the chain is done
                return loc;
            }
            const maybe = path.resolve(path.dirname(loc), path.relative(path.dirname(next), next2));
            if (!isEscape(loc, maybe)) {
                // outside of the guard is a symlink but it is a relative link path
                // we can map within the guard so return that
                return maybe;
            }
            // outside of the guard is a symlink that is not mappable inside the guard
            return loc;
        }
        return next;
    }
    function unguardedRealPath(start, cb) {
        start = String(start); // handle the "undefined" case (matches behavior as fs.realpath)
        const oneHop = (loc, cb) => {
            nextHop(loc, (next) => {
                if (next == undefined) {
                    // file does not exist (broken link)
                    return cb(enoent('realpath', start));
                }
                else if (!next) {
                    // we've hit a real file
                    return cb(null, loc);
                }
                oneHop(next, cb);
            });
        };
        oneHop(start, cb);
    }
    function guardedRealPath(start, cb, escapedRoot = undefined) {
        start = String(start); // handle the "undefined" case (matches behavior as fs.realpath)
        const oneHop = (loc, cb) => {
            nextHop(loc, (next) => {
                if (!next) {
                    // we're no longer hopping but we haven't escaped
                    return fs.exists(loc, (e) => {
                        if (e) {
                            // we hit a real file within the guard and can go no further
                            return cb(null, loc);
                        }
                        else {
                            // something funky happened in the filesystem
                            return cb(enoent('realpath', start));
                        }
                    });
                }
                if (escapedRoot
                    ? isEscape(loc, next, [escapedRoot])
                    : isEscape(loc, next)) {
                    // this hop takes us out of the guard
                    return nextHop(next, (next2) => {
                        if (!next2) {
                            // the chain is done
                            return cb(null, loc);
                        }
                        const maybe = path.resolve(path.dirname(loc), path.relative(path.dirname(next), next2));
                        if (isEscape(loc, maybe)) {
                            // outside of the guard is a symlink that is not mappable inside the guard;
                            // call the unguarded realpath which will throw if the link is dangling;
                            // if it doesn't throw then return the last path within the guard
                            return origRealpath(start, (err, _) => {
                                if (err)
                                    return cb(err);
                                return cb(null, loc);
                            });
                        }
                        return oneHop(maybe, cb);
                    });
                }
                oneHop(next, cb);
            });
        };
        oneHop(start, cb);
    }
    function unguardedRealPathSync(start) {
        start = String(start); // handle the "undefined" case (matches behavior as fs.realpathSync)
        for (let loc = start, next;; loc = next) {
            next = nextHopSync(loc);
            if (next == undefined) {
                // file does not exist (broken link)
                throw enoent('realpath', start);
            }
            else if (!next) {
                // we've hit a real file
                return loc;
            }
        }
    }
    function guardedRealPathSync(start, escapedRoot = undefined) {
        start = String(start); // handle the "undefined" case (matches behavior as fs.realpathSync)
        for (let loc = start, next;; loc = next) {
            next = nextHopSync(loc);
            if (!next) {
                // we're no longer hopping but we haven't escaped
                if (fs.existsSync(loc)) {
                    // we hit a real file within the guard and can go no further
                    return loc;
                }
                else {
                    // something funky happened in the filesystem; throw ENOENT
                    throw enoent('realpath', start);
                }
            }
            if (escapedRoot
                ? isEscape(loc, next, [escapedRoot])
                : isEscape(loc, next)) {
                // this hop takes us out of the guard
                const next2 = nextHopSync(next);
                if (!next2) {
                    // the chain is done
                    return loc;
                }
                const maybe = path.resolve(path.dirname(loc), path.relative(path.dirname(next), next2));
                if (isEscape(loc, maybe)) {
                    // outside of the guard is a symlink that is not mappable inside the guard;
                    // call the unguarded realpath which will throw if the link is dangling;
                    // if it doesn't throw then return the last path within the guard
                    origRealpathSync(start);
                    return loc;
                }
                next = maybe;
                // outside of the guard is a symlink but it is a relative link path
                // we can map within the guard so lets iterate one more time
            }
        }
    }
};
exports.patcher = patcher;
// =========================================================================
// generic helper functions
// =========================================================================
function isSubPath(parent, child) {
    return (parent === child ||
        (child[parent.length] === path.sep && child.startsWith(parent)));
}
exports.isSubPath = isSubPath;
function escapeFunction(_roots) {
    // Ensure roots are always absolute.
    // Sort to ensure escaping multiple roots chooses the longest one.
    const defaultRoots = _roots
        .map((root) => path.resolve(root))
        .sort((a, b) => b.length - a.length);
    function fs_isEscape(linkPath, linkTarget, roots = defaultRoots) {
        // linkPath is the path of the symlink file itself
        // linkTarget is a path that the symlink points to one or more hops away
        // linkTarget must already be normalized
        if (!path.isAbsolute(linkPath)) {
            linkPath = path.resolve(linkPath);
        }
        else {
            linkPath = path.normalize(linkPath);
        }
        for (const root of roots) {
            // If the link is in the root check if the realPath has escaped
            if (isSubPath(root, linkPath) && !isSubPath(root, linkTarget)) {
                return root;
            }
        }
        return false;
    }
    function fs_canEscape(maybeLinkPath, roots = defaultRoots) {
        // maybeLinkPath is the path which may be a symlink
        // maybeLinkPath must already be normalized
        for (const root of roots) {
            // If the link is in the root check if the realPath has escaped
            if (isSubPath(root, maybeLinkPath)) {
                return true;
            }
        }
        return false;
    }
    return {
        isEscape: fs_isEscape,
        canEscape: fs_canEscape,
    };
}
exports.escapeFunction = escapeFunction;
function once(fn) {
    let called = false;
    return (...args) => {
        if (called)
            return;
        called = true;
        let err = false;
        try {
            fn(...args);
        }
        catch (_e) {
            err = _e;
        }
        // blow the stack to make sure this doesn't fall into any unresolved promise contexts
        if (err) {
            setImmediate(() => {
                throw err;
            });
        }
    };
}
function patchDirent(dirent, stat) {
    // add all stat is methods to Dirent instances with their result.
    for (const i in stat) {
        if (i.startsWith('is') && typeof stat[i] === 'function') {
            //
            const result = stat[i]();
            if (result)
                dirent[i] = () => true;
            else
                dirent[i] = () => false;
        }
    }
}
function enoent(s, p) {
    let err = new Error(`ENOENT: no such file or directory, ${s} '${p}'`);
    err.errno = -2;
    err.syscall = s;
    err.code = 'ENOENT';
    err.path = p;
    return err;
}
function einval(s, p) {
    let err = new Error(`EINVAL: invalid argument, ${s} '${p}'`);
    err.errno = -22;
    err.syscall = s;
    err.code = 'EINVAL';
    err.path = p;
    return err;
}
