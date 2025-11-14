#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

TARGET="$1"

# The ports configured in src/BUILD.bazel for the multi-port tests
PORT1=8080
PORT2=8081

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

echo "$$: TEST - $0: $TARGET @ $PORT1 & $PORT2"

./node_modules/.bin/ibazel run "$TARGET" 2>&1 &
ibazel_pid="$!"

function _exit {
    echo "$$: Cleanup..."
    kill "$ibazel_pid"
    wait "$ibazel_pid"
    git checkout src/index.html src/BUILD.bazel
    rm -f src/new.html
}
trap _exit EXIT

echo "$$: Waiting for $TARGET devserver to launch on $PORT1..."

# Wait for $PORT1 to start the http server
n=0
while ! nc -z localhost $PORT1; do
    if [ $n -gt 100 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT1 to be available"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "$$: Waiting for $TARGET devserver to launch on $PORT2..."

# Wait for $PORT2 to start the http server
n=0
while ! nc -z localhost $PORT2; do
    if [ $n -gt 100 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT2 to be available"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

# Verify the initial state of $PORT1 and $PORT2
echo "$$: Devservers ready"

if ! curl http://localhost:$PORT1/index.html --fail 2>/dev/null | grep "My first website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT1/index.html to contain 'My first website'"
    exit 1
fi

if ! curl http://localhost:$PORT2/index.html --fail 2>/dev/null | grep "My first website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT2/index.html to contain 'My first website'"
    exit 1
fi

if ! curl http://localhost:$PORT1/other.html --fail 2>/dev/null | grep "My other website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT1/other.html to contain 'My other website'"
    exit 1
fi

if ! curl http://localhost:$PORT2/other.html --fail 2>/dev/null | grep "My other website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT2/other.html to contain 'My other website'"
    exit 1
fi

if curl http://localhost:$PORT1/new.html --fail 2>/dev/null; then
    echo "$$: ERROR: Expected http://localhost:$PORT1/new.html to fail with 404"
    exit 1
fi

if curl http://localhost:$PORT2/new.html --fail 2>/dev/null; then
    echo "$$: ERROR: Expected http://localhost:$PORT2/new.html to fail with 404"
    exit 1
fi

if curl http://localhost:$PORT1/index.html --fail 2>/dev/null | grep "A second line"; then
    echo "$$: ERROR: Expected http://localhost:$PORT1/index.html to NOT contain 'A second line'"
    exit 1
fi

if curl http://localhost:$PORT2/index.html --fail 2>/dev/null | grep "A second line"; then
    echo "$$: ERROR: Expected http://localhost:$PORT2/index.html to NOT contain 'A second line'"
    exit 1
fi

echo "<div>A second line</div>" >>src/index.html

# Wait for $PORT1 to show the updated file
n=0
while ! curl http://localhost:$PORT1/index.html --fail 2>/dev/null | grep "A second line"; do
    if [ $n -gt 30 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT1/index.html to contain 'A second line'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

# Wait for $PORT2 to show the updated file
n=0
while ! curl http://localhost:$PORT2/index.html --fail 2>/dev/null | grep "A second line"; do
    if [ $n -gt 30 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT2/index.html to contain 'A second line'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "<div>A new file</div>" >src/new.html
_sedi 's#"other.html"#"other.html", "new.html"#' src/BUILD.bazel

# Wait for $PORT1 to show the new file
n=0
while ! curl http://localhost:$PORT1/new.html --fail 2>/dev/null | grep "A new file"; do
    if [ $n -gt 30 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT1/new.html to contain 'A new file'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

# Wait for $PORT2 to show the new file
n=0
while ! curl http://localhost:$PORT2/new.html --fail 2>/dev/null | grep "A new file"; do
    if [ $n -gt 30 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT2/new.html to contain 'A new file'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "$$: All tests passed"
