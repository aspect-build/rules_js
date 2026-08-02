#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Print the auth token on stdout. A real helper would mint or refresh a token here.
printf '%s\n' "${ASPECT_GH_PACKAGES_AUTH_TOKEN:-}"
