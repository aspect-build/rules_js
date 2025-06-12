// Types of internal modules exposes via `--expose-internals`.
// See: https://github.com/nodejs/node/blob/f58613a64c8e02b42391952a6e55a330a7607fa7/typings/internalBinding/fs.d.ts#L17.

declare module 'internal/test/binding' {
  namespace FsInternalModule {
    type InternalStats = { readonly __internalStatsBrandedType: unique symbol };

    const kUsePromises: unique symbol;

    class FSReqCallback {
      constructor(bigint: boolean);
      oncomplete: (err: unknown, stats?: InternalStats) => void;
    }

    function lstat(
      path: string,
      bigint: boolean,
      cb: typeof kUsePromises | FSReqCallback | undefined,
      throwIfNotFound: boolean,
    ): InternalStats | Promise<InternalStats> | undefined;
  }

  function internalBinding(module: 'fs'): typeof FsInternalModule;
}

declare module 'internal/fs/utils' {
  import type { Stats } from 'node:fs';
  import type { FsInternalModule } from 'internal/test/binding';

  function getStatsFromBinding(stat: FsInternalModule.InternalStats): Stats;
}
