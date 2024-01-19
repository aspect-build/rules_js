#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BZLMOD_FLAG="${BZLMOD_FLAG:---enable_bzlmod=1}"

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

echo ""
echo ""
echo "TEST - $0: $1"

ibazel_logs=$(mktemp)
echo "Capturing ibazel logs to $ibazel_logs"
./node_modules/.bin/ibazel run "$1" "$BZLMOD_FLAG" >"$ibazel_logs" 2>&1 &
ibazel_pid="$!"

function _exit {
    kill "$ibazel_pid"
    git checkout src/index.html >/dev/null 2>&1
    git checkout mylib/index.js >/dev/null 2>&1
    rm -f "$ibazel_logs"
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

if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk.blue(packageJson.name)"; then
    echo "ERROR: Expected http://localhost:8080/main.js to contain 'chalk.blue(packageJson.name)'"
    exit 1
fi

_sedi 's#Getting Started#Goodbye#' src/index.html

echo "Waiting 5 seconds for ibazel rebuild after change to src/index.html..."
sleep 5

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "Goodbye"; then
    echo "ERROR: Expected http://localhost:8080/index.html to contain 'Goodbye'"
    exit 1
fi

_sedi 's#blue#red#' mylib/index.js

echo "Waiting 5 seconds for ibazel rebuild after change to mylib/index.js..."
sleep 5

if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk.red(packageJson.name)"; then
    echo "ERROR: Expected http://localhost:8080/main.js to contain 'chalk.red(packageJson.name)'"
    exit 1
fi

echo "Checking log file $ibazel_logs"

count=$(grep -c "Syncing file node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib/index.js" "$ibazel_logs" || true)
if [[ "$count" -ne 2 ]]; then
    echo "ERROR: expected to have synced @mycorp/mylib/index.js 2 times but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib/index.js since its timestamp has not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mylib/index.js due to timestamp 1 time but found ${count}"
    exit 1
fi

count=$(grep -c "Syncing file node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib/package.json" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have synced @mycorp/mylib/package.json 1 time but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib/package.json since its timestamp has not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mylib/package.json due to timestamp 1 time but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib/package.json since contents have not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mylib/package.json due to contents 1 time but found ${count}"
    exit 1
fi

echo "All tests passed"
