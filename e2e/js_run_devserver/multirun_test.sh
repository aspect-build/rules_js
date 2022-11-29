#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi () {
  case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
  esac

  sed "${sedi[@]}" "$@"
}

echo "TEST - $0: $1"

./node_modules/.bin/ibazel run "$1" >/dev/null 2>&1 &
ibazel_pid="$!"

function _exit {
  echo "Cleanup..."
  kill "$ibazel_pid"
  git checkout src/index.html src/BUILD.bazel
  rm -f src/new.html
}
trap _exit EXIT

echo "Waiting for $1 devserver to launch on 8080..."

while ! nc -z localhost 8080; do
  echo "... waiting (8080)"
  sleep 0.5 # wait before check again
done

echo "Waiting for $1 devserver to launch on 8081..."

while ! nc -z localhost 8081; do
  echo "... waiting (8081)"
  sleep 0.5 # wait before check again
done

echo "Waiting 5 seconds for devservers to settle..."
sleep 5

echo "Devservers ready"

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "My first website"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'My first website'"
  exit 1
fi

if ! curl http://localhost:8081/index.html --fail 2>/dev/null | grep "My first website"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'My first website'"
  exit 1
fi

if ! curl http://localhost:8080/other.html --fail 2>/dev/null | grep "My other website"; then
  echo "ERROR: Expected http://localhost:8080/other.html to contain 'My other website'"
  exit 1
fi

if ! curl http://localhost:8081/other.html --fail 2>/dev/null | grep "My other website"; then
  echo "ERROR: Expected http://localhost:8080/other.html to contain 'My other website'"
  exit 1
fi

if curl http://localhost:8080/new.html --fail 2>/dev/null; then
  echo "ERROR: Expected http://localhost:8080/new.html to fail with 404"
  exit 1
fi

if curl http://localhost:8081/new.html --fail 2>/dev/null; then
  echo "ERROR: Expected http://localhost:8080/new.html to fail with 404"
  exit 1
fi

if curl http://localhost:8080/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "ERROR: Expected http://localhost:8080/index.html to NOT contain 'A second line'"
  exit 1
fi

if curl http://localhost:8081/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "ERROR: Expected http://localhost:8080/index.html to NOT contain 'A second line'"
  exit 1
fi

echo "<div>A second line</div>" >> src/index.html

echo "Waiting 5 seconds for ibazel rebuild after change to src/index.html..."
sleep 5

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'A second line'"
  exit 1
fi

if ! curl http://localhost:8081/index.html --fail 2>/dev/null | grep "A second line"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'A second line'"
  exit 1
fi

echo "<div>A new file</div>" > src/new.html
_sedi 's#"other.html"#"other.html", "new.html"#' src/BUILD.bazel

echo "Waiting 10 seconds for ibazel rebuild after change to src/BUILD.bazel..."
sleep 10

if ! curl http://localhost:8080/new.html --fail 2>/dev/null | grep "A new file"; then
  echo "ERROR: Expected http://localhost:8080/new.html to contain 'A new file'"
  exit 1
fi

if ! curl http://localhost:8081/new.html --fail 2>/dev/null | grep "A new file"; then
  echo "ERROR: Expected http://localhost:8080/new.html to contain 'A new file'"
  exit 1
fi

echo "All tests passed"
