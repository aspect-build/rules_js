#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

# On macOS, restore DYLD_INSERT_LIBRARIES from the SIP-safe env var.
# macOS SIP strips DYLD_* vars when exec goes through /bin/bash or /usr/bin/env,
# so the launcher passes the native patch library path via JS_BINARY__NATIVE_PATCH_PATH.
# We set DYLD_INSERT_LIBRARIES here, right before exec'ing the node binary (which is
# not SIP-restricted), so the dynamic linker will load our interpose library.
if [ "${JS_BINARY__NATIVE_PATCH_PATH:-}" ]; then
    if [ -z "${DYLD_INSERT_LIBRARIES:-}" ]; then
        export DYLD_INSERT_LIBRARIES="$JS_BINARY__NATIVE_PATCH_PATH"
    else
        export DYLD_INSERT_LIBRARIES="$JS_BINARY__NATIVE_PATCH_PATH:$DYLD_INSERT_LIBRARIES"
    fi
fi

exec "$JS_BINARY__NODE_BINARY" --require "$JS_BINARY__NODE_PATCHES" "$@"
