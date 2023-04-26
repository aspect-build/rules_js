#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:-}"

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi () {
  case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
  esac

  sed "${sedi[@]}" "$@"
}

echo "$$: TEST - $0: $1"

./node_modules/.bin/ibazel run "$1" "$BZLMOD_FLAG" >/dev/null 2>&1 &
ibazel_pid="$!"

function _exit {
  echo "$$: Cleanup..."
  kill "$ibazel_pid"
  wait "$ibazel_pid"
  git checkout src/index.html src/BUILD.bazel
  rm -f src/new.html
}
trap _exit EXIT

echo "$$: Waiting for $1 devserver to launch on 8080..."

n=0
while ! nc -z localhost 8080; do
  if [ $n -gt 100 ]; then
    echo "$$: ERROR: Expected http://localhost:8080 to be available"
    exit 1
  fi
  sleep 1 # wait before check again
  ((n=n+1))
done

echo "$$: Waiting for $1 devserver to launch on 8081..."

n=0
while ! nc -z localhost 8081; do
  if [ $n -gt 100 ]; then
    echo "$$: ERROR: Expected http://localhost:8081 to be available"
    exit 1
  fi
  sleep 1 # wait before check again
  ((n=n+1))
done

echo "$$: Devservers ready"

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "My first website"; then
  echo "$$: ERROR: Expected http://localhost:8080/index.html to contain 'My first website'"
  exit 1
fi

if ! curl http://localhost:8081/index.html --fail 2>/dev/null | grep "My first website"; then
  echo "$$: ERROR: Expected http://localhost:8081/index.html to contain 'My first website'"
  exit 1
fi

if ! curl http://localhost:8080/other.html --fail 2>/dev/null | grep "My other website"; then
  echo "$$: ERROR: Expected http://localhost:8080/other.html to contain 'My other website'"
  exit 1
fi

if ! curl http://localhost:8081/other.html --fail 2>/dev/null | grep "My other website"; then
  echo "$$: ERROR: Expected http://localhost:8081/other.html to contain 'My other website'"
  exit 1
fi

if curl http://localhost:8080/new.html --fail 2>/dev/null; then
  echo "$$: ERROR: Expected http://localhost:8080/new.html to fail with 404"
  exit 1
fi

if curl http://localhost:8081/new.html --fail 2>/dev/null; then
  echo "$$: ERROR: Expected http://localhost:8081/new.html to fail with 404"
  exit 1
fi

if curl http://localhost:8080/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "$$: ERROR: Expected http://localhost:8080/index.html to NOT contain 'A second line'"
  exit 1
fi

if curl http://localhost:8081/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "$$: ERROR: Expected http://localhost:8081/index.html to NOT contain 'A second line'"
  exit 1
fi

echo "$$: <div>A second line</div>" >> src/index.html

n=0
while ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "A second line"; do
  if [ $n -gt 30 ]; then
    echo "$$: ERROR: Expected http://localhost:8080/index.html to contain 'A second line'"
    exit 1
  fi
  sleep 1 # wait before check again
  ((n=n+1))
done

if ! curl http://localhost:8081/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "$$: ERROR: Expected http://localhost:8081/index.html to contain 'A second line'"
  exit 1
fi

echo "$$: <div>A new file</div>" > src/new.html
_sedi 's#"other.html"#"other.html", "new.html"#' src/BUILD.bazel

n=0
while ! curl http://localhost:8080/new.html --fail 2>/dev/null | grep "A new file"; do
  if [ $n -gt 30 ]; then
    echo "$$: ERROR: Expected http://localhost:8080/new.html to contain 'A new file'"
    exit 1
  fi
  sleep 1 # wait before check again
  ((n=n+1))
done

if ! curl http://localhost:8081/new.html --fail 2>/dev/null | grep "A new file"; then
  echo "$$: ERROR: Expected http://localhost:8080/new.html to contain 'A new file'"
  exit 1
fi

echo "$$: All tests passed"
