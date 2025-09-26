// Patches Node's internal FS bindings, right before they would call into C++.
// See full context in: https://github.com/aspect-build/rules_js/issues/362.
// This is to ensure ESM imports don't escape accidentally via `realpathSync`.

/// <reference path="./fs_stat_types.d.cts" />

import { internalBinding, FsInternalModule } from 'internal/test/binding';
import { getStatsFromBinding } from 'internal/fs/utils';
import { resolvePathLike, type escapeFunction } from './fs.cjs';

const internalFs = internalBinding('fs');

export class FsInternalStatPatcher {
  private _originalFsLstat = internalFs.lstat;

  constructor(
    private escapeFns: ReturnType<typeof escapeFunction>,
    private guardedReadLink: (start: string, cb: (str: string) => void) => void,
    private guardedReadLinkSync: (start: string) => string,
    private unguardedRealPath: (start: string, cb: (err: Error, str?: string) => void) => void,
    private unguardedRealPathSync: (start: string) => string,
  ) {}

  revert() {
    internalFs.lstat = this._originalFsLstat;
  }

  patch() {
    const statPatcher = this;

    internalFs.lstat = function (path, bigint, reqCallback, throwIfNoEntry) {
      const currentStack = new Error().stack;
      const needsGuarding =
        currentStack &&
        (currentStack.includes('finalizeResolution (node:internal/modules/esm/resolve') &&
        !currentStack.includes('eeguardStats'));

      if (!needsGuarding) {
        return statPatcher._originalFsLstat.call(
          internalFs,
          path,
          bigint,
          reqCallback,
          throwIfNoEntry,
        );
      }

      if (reqCallback === internalFs.kUsePromises) {
        return (
          statPatcher._originalFsLstat.call(
            internalFs,
            path,
            bigint,
            reqCallback,
            throwIfNoEntry,
          ) as Promise<FsInternalModule.InternalStats>
        ).then((stats) => {
          return new Promise((resolve, reject) => {
            statPatcher.eeguardStats(path, bigint, stats, throwIfNoEntry, (err, guardedStats) => {
              err || !guardedStats ? reject(err) : resolve(guardedStats);
            });
          });
        });
      } else if (reqCallback === undefined) {
        const stats = statPatcher._originalFsLstat.call(
          internalFs,
          path,
          bigint,
          undefined,
          throwIfNoEntry,
        ) as FsInternalModule.InternalStats;
        if (!stats) {
          return stats;
        }
        return statPatcher.eeguardStatsSync(path, bigint, throwIfNoEntry, stats);
      } else {
        // Just re-use the promise path from above.
        (
          internalFs.lstat(
            path,
            bigint,
            internalFs.kUsePromises,
            throwIfNoEntry,
          ) as Promise<FsInternalModule.InternalStats>
        )
          .then((stats) => reqCallback.oncomplete(null, stats))
          .catch((err) => reqCallback.oncomplete(err));
      }
    };
  }

  eeguardStats(
    path: string,
    bigint: boolean,
    stats: FsInternalModule.InternalStats,
    throwIfNotFound: boolean,
    cb: (err: unknown, stats?: FsInternalModule.InternalStats) => void,
  ) {
    const statsObj = getStatsFromBinding(stats);
    if (!statsObj.isSymbolicLink()) {
      // the file is not a symbolic link so there is nothing more to do
      return cb(null, stats);
    }

    path = resolvePathLike(path);
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
          if ((err as Partial<{ code: string }>).code === 'ENOENT') {
            // broken link so there is nothing more to do
            return cb(null, stats);
          }
          return cb(err);
        }

        // Forward request to original callback.
        const req2 = new internalFs.FSReqCallback(bigint);
        req2.oncomplete = (err, realStats) => cb(err, realStats);
        return this._originalFsLstat.call(internalFs, str!, bigint, req2, throwIfNotFound);
      });
    });
  }

  eeguardStatsSync(
    path: string,
    bigint: boolean,
    throwIfNoEntry: boolean,
    stats: FsInternalModule.InternalStats,
  ): FsInternalModule.InternalStats {
    // No stats available.
    if (!stats) {
      return stats;
    }

    const statsObj = getStatsFromBinding(stats);
    if (!statsObj.isSymbolicLink()) {
      // the file is not a symbolic link so there is nothing more to do
      return stats;
    }

    path = resolvePathLike(path);
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
      return this._originalFsLstat.call(
        internalFs,
        path,
        bigint,
        undefined,
        throwIfNoEntry,
      ) as FsInternalModule.InternalStats;
    } catch (err) {
      if ((err as Partial<{ code: string }>).code === 'ENOENT') {
        // broken link so there is nothing more to do
        return stats;
      }
      throw err;
    }
  }
}
