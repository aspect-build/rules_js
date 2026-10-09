#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for Next.js devservers run with js_run_devserver

./devserver_test.sh //v15/mjs/devserver:dev_turbopack
./devserver_test.sh //v15/mjs/devserver:dev_webpack

echo "test.sh: PASS"
