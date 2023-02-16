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

echo "TEST - $0: $1"

./node_modules/.bin/ibazel run "$1" "$BZLMOD_FLAG" >/dev/null 2>&1 &
ibazel_pid="$!"

function _exit {
  echo "Cleanup..."
  kill "$ibazel_pid"
  git checkout src/index.html
}
trap _exit EXIT

echo "Waiting for $1 devserver to launch on 8080..."

while ! nc -z localhost 8080; do
  echo "."
  sleep 0.5 # wait before check again
done

echo "Waiting 5 seconds for devservers to settle..."
sleep 5

echo "Devserver ready"

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "Getting Started"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'Getting Started'"
  exit 1
fi

_sedi 's#Getting Started#Goodbye#' src/index.html

echo "Waiting 5 seconds for ibazel rebuild after change to src/index.html..."
sleep 5

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "Goodbye"; then
  echo "ERROR: Expected http://localhost:8080/index.html to contain 'Goodbye'"
  exit 1
fi

echo "All tests passed"
