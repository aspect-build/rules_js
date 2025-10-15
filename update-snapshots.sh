#!/usr/bin/env bash
# Update all snapshots and generated sources across the repository

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_section() {
  echo -e "${BLUE}==> $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_category() {
  echo ""
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}$1${NC}"
  echo -e "${YELLOW}========================================${NC}"
}

# Track failures
FAILED_TARGETS=()

run_target() {
  local dir="$1"
  local target="$2"
  local description="$3"
  local extra_flags="${4:-}"

  echo ""
  print_section "$description"
  if (cd "$dir" && bazel run $extra_flags "$target"); then
    print_success "$description"
  else
    echo "✗ Failed: $description"
    FAILED_TARGETS+=("$dir -> $target")
  fi
}

echo "========================================"
echo "Updating all snapshots and sources..."
echo "========================================"

##############################################################################
# E2E TEST SNAPSHOTS
##############################################################################

print_category "E2E TEST SNAPSHOTS"

# pnpm_lockfiles - Multiple versions (bzlmod only, no workspace mode in this repo)
for version in v54 v60 v61 v90 v101; do
  run_target "$REPO_ROOT/e2e/pnpm_lockfiles" "//$version:repos" "pnpm_lockfiles/$version"
done

# npm_translate_lock
run_target "$REPO_ROOT/e2e/npm_translate_lock" "//:write_npm_translate_lock_wksp" "npm_translate_lock" "--enable_bzlmod=false"

# npm_translate_lock_empty
run_target "$REPO_ROOT/e2e/npm_translate_lock_empty" "//:write_npm_translate_lock_wksp" "npm_translate_lock_empty" "--enable_bzlmod=false"

# npm_translate_lock_replace_packages
run_target "$REPO_ROOT/e2e/npm_translate_lock_replace_packages" "//:write_npm_translate_lock_wksp" "npm_translate_lock_replace_packages (wksp)" "--enable_bzlmod=false"
run_target "$REPO_ROOT/e2e/npm_translate_lock_replace_packages" "//:write_npm_translate_lock_bzlmod" "npm_translate_lock_replace_packages (bzlmod)"

# npm_translate_lock_disable_hooks
run_target "$REPO_ROOT/e2e/npm_translate_lock_disable_hooks" "//:write_npm_translate_lock_wksp" "npm_translate_lock_disable_hooks (wksp)" "--enable_bzlmod=false"
run_target "$REPO_ROOT/e2e/npm_translate_lock_disable_hooks" "//:write_npm_translate_lock_defs" "npm_translate_lock_disable_hooks (defs)"

# gyp_no_install_script
run_target "$REPO_ROOT/e2e/gyp_no_install_script" "//:write_npm_translate_lock_wksp" "gyp_no_install_script (wksp)" "--enable_bzlmod=false"
run_target "$REPO_ROOT/e2e/gyp_no_install_script" "//:write_npm_translate_lock_bzlmod" "gyp_no_install_script (bzlmod)"

# pnpm_workspace
run_target "$REPO_ROOT/e2e/pnpm_workspace" "//:repos" "pnpm_workspace"

# pnpm_workspace_rerooted
run_target "$REPO_ROOT/e2e/pnpm_workspace_rerooted" "//:repos" "pnpm_workspace_rerooted"

##############################################################################
# ROOT TEST SNAPSHOTS
##############################################################################

print_category "ROOT TEST SNAPSHOTS"

# npm/private/test - npm translation test snapshots
run_target "$REPO_ROOT" "//npm/private/test:write_npm_translate_lock" "npm/private/test"

# js/private/test - js_binary launcher snapshot
run_target "$REPO_ROOT" "//js/private/test:write_launcher" "js/private/test"

##############################################################################
# GENERATED SOURCES
##############################################################################

print_category "GENERATED SOURCES"

# Watch protocol
run_target "$REPO_ROOT" "//js/private/watch:watch_checked" "Watch protocol"

# Devserver bundle
run_target "$REPO_ROOT" "//js/private/devserver:watch_checked" "Devserver bundle"

# Worker bundle
run_target "$REPO_ROOT" "//js/private/worker:worker_checked" "Worker bundle"

# Node patches
run_target "$REPO_ROOT" "//js/private/node-patches:checked_in_compile" "Node patches"

# Coverage bundle
run_target "$REPO_ROOT" "//js/private/coverage:coverage_checked" "Coverage bundle"

##############################################################################
# SUMMARY
##############################################################################

echo ""
echo "========================================"
if [ ${#FAILED_TARGETS[@]} -eq 0 ]; then
  print_success "All updates completed successfully!"
else
  echo "✗ Some targets failed:"
  for failed in "${FAILED_TARGETS[@]}"; do
    echo "  - $failed"
  done
  exit 1
fi
echo "========================================"
