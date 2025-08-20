# Demo of Node-Gyp indeterminism 

Recently fixed in very latest release (>=v11.3.0), but many packages are pinned to older versions of node-gyp
https://github.com/nodejs/gyp-next/pull/293

## Repro

```sh
bazel run //:node-gyp-determinism
# Observe SHA256 of makefile printed out

bazel clean --async --expunge 

bazel run //:node-gyp-determinism
# Observe SHA256 has (likely) changed
```

## Fix

Apply PR #2321 and see the file is removed, which should not be relied on. 
