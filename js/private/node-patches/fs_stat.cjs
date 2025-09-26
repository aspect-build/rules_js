"use strict";
// Patches Node's internal FS bindings, right before they would call into C++.
// See full context in: https://github.com/aspect-build/rules_js/issues/362.
// This is to ensure ESM imports don't escape accidentally via `realpathSync`.
Object.defineProperty(exports, "__esModule", { value: true });
exports.FsInternalStatPatcher = void 0;
/// <reference path="./fs_stat_types.d.cts" />
const binding_1 = require("internal/test/binding");
const utils_1 = require("internal/fs/utils");
const fs_cjs_1 = require("./fs.cjs");
const internalFs = (0, binding_1.internalBinding)('fs');
class FsInternalStatPatcher {
    constructor(escapeFns, guardedReadLink, guardedReadLinkSync, unguardedRealPath, unguardedRealPathSync) {
        this.escapeFns = escapeFns;
        this.guardedReadLink = guardedReadLink;
        this.guardedReadLinkSync = guardedReadLinkSync;
        this.unguardedRealPath = unguardedRealPath;
        this.unguardedRealPathSync = unguardedRealPathSync;
        this._originalFsLstat = internalFs.lstat;
        this.originalSyncRequested = false;
    }
    revert() {
        internalFs.lstat = this._originalFsLstat;
    }
    patch() {
        const statPatcher = this;
        internalFs.lstat = function (path, bigint, reqCallback, throwIfNoEntry) {
            if (this.originalSyncRequested) {
                return statPatcher._originalFsLstat.call(internalFs, path, bigint, reqCallback, throwIfNoEntry);
            }
            if (reqCallback === internalFs.kUsePromises) {
                return statPatcher._originalFsLstat.call(internalFs, path, bigint, reqCallback, throwIfNoEntry).then((stats) => {
                    return new Promise((resolve, reject) => {
                        statPatcher.eeguardStats(path, bigint, stats, throwIfNoEntry, (err, guardedStats) => {
                            err || !guardedStats ? reject(err) : resolve(guardedStats);
                        });
                    });
                });
            }
            else if (reqCallback === undefined) {
                const stats = statPatcher._originalFsLstat.call(internalFs, path, bigint, undefined, throwIfNoEntry);
                if (!stats) {
                    return stats;
                }
                return statPatcher.eeguardStatsSync(path, bigint, throwIfNoEntry, stats);
            }
            else {
                // Just re-use the promise path from above.
                internalFs.lstat(path, bigint, internalFs.kUsePromises, throwIfNoEntry)
                    .then((stats) => reqCallback.oncomplete(null, stats))
                    .catch((err) => reqCallback.oncomplete(err));
            }
        };
    }
    eeguardStats(path, bigint, stats, throwIfNotFound, cb) {
        const statsObj = (0, utils_1.getStatsFromBinding)(stats);
        if (!statsObj.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return cb(null, stats);
        }
        path = (0, fs_cjs_1.resolvePathLike)(path);
        if (!this.escapeFns.canEscape(path)) {
            // the file can not escaped the sandbox so there is nothing more to do
            return cb(null, stats);
        }
        return this.guardedReadLink(path, (str) => {
            if (str != path) {
                // there are one or more hops within the guards so there is nothing more to do
                return cb(null, stats);
            }
            // there are no hops so lets report the stats of the real file;
            // we can't use origRealPath here since that function calls lstat internally
            // which can result in an infinite loop
            return this.unguardedRealPath(path, (err, str) => {
                if (err) {
                    if (err.code === 'ENOENT') {
                        // broken link so there is nothing more to do
                        return cb(null, stats);
                    }
                    return cb(err);
                }
                // Forward request to original callback.
                const req2 = new internalFs.FSReqCallback(bigint);
                req2.oncomplete = (err, realStats) => cb(err, realStats);
                return this._originalFsLstat.call(internalFs, str, bigint, req2, throwIfNotFound);
            });
        });
    }
    eeguardStatsSync(path, bigint, throwIfNoEntry, stats) {
        // No stats available.
        if (!stats) {
            return stats;
        }
        const statsObj = (0, utils_1.getStatsFromBinding)(stats);
        if (!statsObj.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return stats;
        }
        path = (0, fs_cjs_1.resolvePathLike)(path);
        if (!this.escapeFns.canEscape(path)) {
            // the file can not escaped the sandbox so there is nothing more to do
            return stats;
        }
        const guardedReadLink = this.guardedReadLinkSync(path);
        if (guardedReadLink != path) {
            // there are one or more hops within the guards so there is nothing more to do
            return stats;
        }
        try {
            path = this.unguardedRealPathSync(path);
            // there are no hops so lets report the stats of the real file;
            // we can't use origRealPathSync here since that function calls lstat internally
            // which can result in an infinite loop
            return this._originalFsLstat.call(internalFs, path, bigint, undefined, throwIfNoEntry);
        }
        catch (err) {
            if (err.code === 'ENOENT') {
                // broken link so there is nothing more to do
                return stats;
            }
            throw err;
        }
    }
}
exports.FsInternalStatPatcher = FsInternalStatPatcher;
