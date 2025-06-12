// Patches Node's internal FS bindings, right before they would call into C++.
// See full context in: https://github.com/aspect-build/rules_js/issues/362.
// This is to ensure ESM imports don't escape accidentally via `realpathSync`.

/// <reference path="./fs_stat_types.d.cts" />

import { internalBinding, FsInternalModule } from 'internal/test/binding'
import { getStatsFromBinding } from 'internal/fs/utils'
import { resolvePathLike, type escapeFunction } from './fs.cjs'

const internalFs = internalBinding('fs')
const internalFsLStat = internalFs.lstat

export class FsInternalStatPatcher {
    constructor(
        private readonly escapeFns: ReturnType<typeof escapeFunction>,
        private readonly guardedReadLink: (
            start: string,
            cb: (str: string) => void
        ) => void,
        private readonly guardedReadLinkSync: (start: string) => string,
        private readonly unguardedRealPath: (
            start: string,
            cb: (err: Error | null, str?: string) => void
        ) => void,
        private readonly unguardedRealPathSync: (start: string) => string
    ) {}

    revert() {
        internalFs.lstat = internalFsLStat
    }

    patch() {
        const statPatcher = this

        internalFs.lstat = function (
            path,
            bigint,
            reqCallback,
            throwIfNoEntry?: boolean
        ) {
            const currentStack = new Error().stack
            // Patch the internalFs.lstat call
            //  from realpathSync: https://github.com/nodejs/node/blob/v25.2.1/lib/fs.js#L2752
            //  invoked from finalizeResolution: https://github.com/nodejs/node/blob/v25.2.1/lib/internal/modules/esm/resolve.js#L279
            //  while avoiding recursive calls.
            const needsGuarding =
                currentStack &&
                currentStack.includes(
                    'finalizeResolution (node:internal/modules/esm/resolve'
                ) &&
                !currentStack.includes('eeguardStats')

            if (!needsGuarding) {
                return internalFsLStat.apply(internalFs, arguments as any)
            }

            if (reqCallback === internalFs.kUsePromises) {
                return internalFsLStat
                    .call(internalFs, path, bigint, reqCallback)
                    .then((stats) => {
                        return new Promise((resolve, reject) => {
                            statPatcher.eeguardStats(
                                resolvePathLike(path),
                                bigint,
                                stats,
                                !!throwIfNoEntry,
                                (err, guardedStats) => {
                                    err
                                        ? reject(err)
                                        : resolve(guardedStats as any)
                                }
                            )
                        })
                    })
            } else if (reqCallback === undefined) {
                const stats = internalFsLStat.apply(
                    internalFs,
                    arguments as any
                ) as any as FsInternalModule.InternalStats
                if (!stats) {
                    return stats
                }
                return statPatcher.eeguardStatsSync(
                    resolvePathLike(path),
                    bigint,
                    !!throwIfNoEntry,
                    stats
                )
            } else {
                // Just re-use the promise path from above.
                internalFs
                    .lstat(path, bigint, internalFs.kUsePromises)
                    .then((stats) => reqCallback.oncomplete(null, stats))
                    .catch((err) => reqCallback.oncomplete(err))
                return undefined as any
            }
        }
    }

    eeguardStats(
        path: string,
        bigint: boolean,
        stats: FsInternalModule.InternalStats | undefined,
        throwIfNotFound: boolean,
        cb: (err: unknown, stats?: FsInternalModule.InternalStats) => void
    ) {
        if (!stats) {
            if (throwIfNotFound) {
                return cb(new Error('ENOENT'))
            }
            return cb(null, stats)
        }
        const statsObj = getStatsFromBinding(stats)
        if (!statsObj.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return cb(null, stats)
        }

        path = resolvePathLike(path)
        if (!this.escapeFns.canEscape(path)) {
            // the file can not escaped the sandbox so there is nothing more to do
            return cb(null, stats)
        }

        return this.guardedReadLink(path, (str) => {
            if (str != path) {
                // there are one or more hops within the guards so there is nothing more to do
                return cb(null, stats)
            }
            // there are no hops so lets report the stats of the real file;
            // we can't use origRealPath here since that function calls lstat internally
            // which can result in an infinite loop.
            return this.unguardedRealPath(path, (err, str) => {
                if (err) {
                    if ((err as Partial<{ code: string }>).code === 'ENOENT') {
                        // broken link so there is nothing more to do
                        return cb(null, stats)
                    }
                    return cb(err)
                }

                // Forward request to original callback.
                const req2 = new internalFs.FSReqCallback(bigint)
                req2.oncomplete = (err, realStats) => cb(err, realStats)
                return internalFsLStat.call(
                    internalFs,
                    str!,
                    bigint,
                    req2 as any // TODO: why type mismatch here?
                )
            })
        })
    }

    eeguardStatsSync(
        path: string,
        bigint: boolean,
        throwIfNoEntry: boolean,
        stats: FsInternalModule.InternalStats
    ): FsInternalModule.InternalStats {
        // No stats available
        if (!stats) {
            return stats
        }

        const statsObj = getStatsFromBinding(stats)
        if (!statsObj.isSymbolicLink()) {
            // the file is not a symbolic link so there is nothing more to do
            return stats
        }

        path = resolvePathLike(path)
        if (!this.escapeFns.canEscape(path)) {
            // the file can not escaped the sandbox so there is nothing more to do
            return stats
        }

        const guardedReadLink = this.guardedReadLinkSync(path)
        if (guardedReadLink != path) {
            // there are one or more hops within the guards so there is nothing more to do
            return stats
        }
        try {
            path = this.unguardedRealPathSync(path)
            // there are no hops so lets report the stats of the real file;
            // we can't use origRealPathSync here since that function calls lstat internally
            // which can result in an infinite loop
            // TODO: typing
            return (internalFsLStat as any).call(
                internalFs,
                path,
                bigint,
                undefined,
                throwIfNoEntry
            )
        } catch (err) {
            if ((err as Partial<{ code: string }>).code === 'ENOENT') {
                // broken link so there is nothing more to do
                return stats
            }
            throw err
        }
    }
}
