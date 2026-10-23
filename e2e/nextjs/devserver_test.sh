#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Runs a Next.js js_run_devserver target and checks that it serves a page.

TARGET="$1"

PORT=$((4080 + RANDOM))
while netstat -a | grep $PORT; do
    PORT=$((4080 + RANDOM))
done
export PORT

echo "$$: TEST - $0: $TARGET @ $PORT"

# In its own process group so that next, a child of the devserver, is stopped along with it
setsid bazel run "$TARGET" 2>&1 &
devserver_pid="$!"

function _exit {
    echo "$$: Cleanup..."
    # SIGINT, on which the devserver deletes its sandbox
    kill -INT -- "-$devserver_pid" 2>/dev/null || true
    wait "$devserver_pid" 2>/dev/null || true
}
trap _exit EXIT

# The first request compiles the page, so allow for the build, startup and compilation
n=0
while ! curl http://localhost:$PORT/ --fail --silent | grep --quiet "Hello from the devserver"; do
    if ! kill -0 "$devserver_pid" 2>/dev/null; then
        echo "$$: ERROR: Expected $TARGET to keep running"
        exit 1
    fi
    if [ $n -gt 300 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT/ to contain 'Hello from the devserver'"
        exit 1
    fi
    sleep 1
    ((n = n + 1))
done

echo "$$: All tests passed"
