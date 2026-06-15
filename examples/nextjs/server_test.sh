#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SERVER="$1"
PORT=3099
TIMEOUT=30

export PORT
"$SERVER" &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

for i in $(seq 1 "$TIMEOUT"); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "FAIL: Server process died before responding"
        exit 1
    fi
    if curl -sf "http://localhost:$PORT/" > /dev/null 2>&1; then
        echo "PASS: Next.js standalone server responded on port $PORT"
        exit 0
    fi
    sleep 1
done

echo "FAIL: Server did not respond within $TIMEOUT seconds"
exit 1
