#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

TARGET="$1"

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

# Find a random unused port to use
PORT=$((4080 + RANDOM))
while netstat -a | grep $PORT; do
    PORT=$((4080 + RANDOM))
done
export PORT

echo "$$: TEST - $0: $TARGET @ $PORT"

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

echo "$$: Waiting for $TARGET devserver to launch on $PORT..."

# Wait for $PORT to start the http server
n=0
while ! nc -z localhost $PORT; do
    if [ $n -gt 100 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT to be available"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "$$: Devserver ready"

if ! curl http://localhost:$PORT/index.html --fail 2>/dev/null | grep "My first website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT/index.html to contain 'My first website'"
    exit 1
fi

if ! curl http://localhost:$PORT/other.html --fail 2>/dev/null | grep "My other website"; then
    echo "$$: ERROR: Expected http://localhost:$PORT/other.html to contain 'My other website'"
    exit 1
fi

if curl http://localhost:$PORT/new.html --fail 2>/dev/null; then
    echo "$$: ERROR: Expected http://localhost:$PORT/new.html to fail with 404"
    exit 1
fi

if curl http://localhost:$PORT/index.html --fail 2>/dev/null | grep "A second line"; then
    echo "$$: ERROR: Expected http://localhost:$PORT/index.html to NOT contain 'A second line'"
    exit 1
fi

echo "<div>A second line</div>" >>src/index.html

# Wait for $PORT to show the updated file
n=0
while ! curl http://localhost:$PORT/index.html --fail 2>/dev/null | grep "A second line"; do
    if [ $n -gt 30 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT/index.html to contain 'A second line'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "<div>A new file</div>" >src/new.html
_sedi 's#"other.html"#"other.html", "new.html"#' src/BUILD.bazel

# Wait for $PORT to show the new file
n=0
while ! curl http://localhost:$PORT/new.html --fail 2>/dev/null | grep "A new file"; do
    if [ $n -gt 60 ]; then
        echo "$$: ERROR: Expected http://localhost:$PORT/new.html to contain 'A new file'"
        exit 1
    fi
    sleep 1 # wait before check again
    ((n = n + 1))
done

echo "$$: All tests passed"
