#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Integration test for npmrc_auth_file + tokenHelper. rules_js reads the trusted auth
# file named by npmrc_auth_file and runs its tokenHelper to authenticate to the private
# @aspect-build registry. A bad token would 401 the fetch, so a green build proves the
# helper ran and its output was used.

# sedi makes `sed -i` work on both OSX & Linux
# See https://stackoverflow.com/questions/2320564/i-need-my-sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd
_sedi() {
    case $(uname) in
    Darwin*) sedi=('-i' '') ;;
    *) sedi=('-i') ;;
    esac

    sed "${sedi[@]}" "$@"
}

dir="$(cd "$(dirname "$0")" && pwd)"

# tokenHelper and npmrc_auth_file both require absolute paths not known until runtime.
_sedi "s#__TOKEN_HELPER__#${dir}/token-helper.sh#" auth.npmrc
_sedi "s#__NPMRC_AUTH_FILE__#${dir}/auth.npmrc#" MODULE.bazel

bazel test //...
