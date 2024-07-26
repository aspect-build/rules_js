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

echo "TEST - $0: $1"

ibazel_logs=$(mktemp)
echo "Capturing ibazel logs to $ibazel_logs"
./node_modules/.bin/ibazel run "$1" "$BZLMOD_FLAG" >"$ibazel_logs" 2>&1 &
ibazel_pid="$!"

function _exit {
    kill "$ibazel_pid"
    git checkout src/index.html >/dev/null 2>&1
    git checkout mypkg/index.js >/dev/null 2>&1
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

# from @mycorp/mypkg
if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk__WEBPACK_IMPORTED_MODULE_1___default().blue(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)"; then
    echo "ERROR: http://localhost:8080/main.js to contain 'chalk__WEBPACK_IMPORTED_MODULE_1___default().blue(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)'"
    exit 1
fi

# from @mycorp/mylib
if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk__WEBPACK_IMPORTED_MODULE_1___default().blue(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)"; then
    echo "ERROR: http://localhost:8080/main.js to contain 'chalk__WEBPACK_IMPORTED_MODULE_1___default().green(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)'"
    exit 1
fi

_sedi 's#Getting Started#Goodbye#' src/index.html

echo "Waiting 5 seconds for ibazel rebuild after change to src/index.html..."
sleep 5

if ! curl http://localhost:8080/index.html --fail 2>/dev/null | grep "Goodbye"; then
    echo "ERROR: Expected http://localhost:8080/index.html to contain 'Goodbye'"
    exit 1
fi

_sedi 's#blue#red#' mypkg/index.js

echo "Waiting 5 seconds for ibazel rebuild after change to mypkg/index.js..."
sleep 5

# from @mycorp/mypkg
if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk__WEBPACK_IMPORTED_MODULE_1___default().red(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)"; then
    echo "ERROR: Expected http://localhost:8080/main.js to contain 'chalk__WEBPACK_IMPORTED_MODULE_1___default().red(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)'"
    exit 1
fi

_sedi 's#green#cyan#' mylib/index.js

echo "Waiting 5 seconds for ibazel rebuild after change to mylib/index.js..."
sleep 5

# from @mycorp/mylib
if ! curl http://localhost:8080/main.js --fail 2>/dev/null | grep "chalk__WEBPACK_IMPORTED_MODULE_1___default().cyan(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)"; then
    echo "ERROR: Expected http://localhost:8080/main.js to contain 'chalk__WEBPACK_IMPORTED_MODULE_1___default().cyan(_package_json__WEBPACK_IMPORTED_MODULE_0__.name)'"
    exit 1
fi

count=$(grep -c "Syncing symlink node_modules/.aspect_rules_js/@mycorp+mylib@0.0.0/node_modules/@mycorp/mylib (1p)" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have synced @mycorp/mylib symlink 1 time but found ${count}"
    exit 1
fi

count=$(grep -c "Syncing file node_modules/.aspect_rules_js/@mycorp+mypkg@0.0.0/node_modules/@mycorp/mypkg/index.js" "$ibazel_logs" || true)
if [[ "$count" -ne 2 ]]; then
    echo "ERROR: expected to have synced @mycorp/mypkg/index.js 2 times but found ${count}"
    exit 1
fi

count=$(grep -c "Syncing file mylib/index.js" "$ibazel_logs" || true)
if [[ "$count" -ne 2 ]]; then
    echo "ERROR: expected to have synced mylib/index.js 2 times but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mypkg@0.0.0/node_modules/@mycorp/mypkg/index.js since its timestamp has not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 2 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mypkg/index.js due to timestamp 2 times but found ${count}"
    exit 1
fi

count=$(grep -c "Syncing file node_modules/.aspect_rules_js/@mycorp+mypkg@0.0.0/node_modules/@mycorp/mypkg/package.json" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have synced @mycorp/mypkg/package.json 1 time but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mypkg@0.0.0/node_modules/@mycorp/mypkg/package.json since its timestamp has not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 2 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mypkg/package.json due to timestamp 2 times but found ${count}"
    exit 1
fi

count=$(grep -c "Skipping file node_modules/.aspect_rules_js/@mycorp+mypkg@0.0.0/node_modules/@mycorp/mypkg/package.json since contents have not changed" "$ibazel_logs" || true)
if [[ "$count" -ne 1 ]]; then
    echo "ERROR: expected to have skipped @mycorp/mypkg/package.json due to contents 1 times but found ${count}"
    exit 1
fi

echo "All tests passed"
