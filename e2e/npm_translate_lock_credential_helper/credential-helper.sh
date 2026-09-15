#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# A Bazel credential helper: `get` reads {"uri": ...} on stdin and prints the headers for it.
# A real helper would mint or refresh a token here.
[ "$1" = "get" ] || exit 1

case "$(cat)" in
*npm.pkg.github.com*) token="${ASPECT_GH_PACKAGES_AUTH_TOKEN:-}" ;;
*registry.npmjs.org*) token="${ASPECT_NPM_AUTH_TOKEN:-}" ;;
*)
    echo '{"headers":{}}'
    exit 0
    ;;
esac

printf '{"headers":{"Authorization":["Bearer %s"]}}\n' "$token"
