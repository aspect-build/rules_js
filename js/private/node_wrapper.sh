#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

if [[ "${JS_BINARY__PATCH_NODE_ESM_LOADER:-}" == "1" ]]; then
  # --expose-internals is needed for FS esm patches.

  #--disable-warning=internal/test/binding
  
  exec "$JS_BINARY__NODE_BINARY" \
    --expose-internals \
    --inspect-brk \
    --require "$JS_BINARY__NODE_PATCHES" "$@"
else
  exec "$JS_BINARY__NODE_BINARY" --require "$JS_BINARY__NODE_PATCHES" "$@"
fi
