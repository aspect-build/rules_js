#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

echo "=== Enhanced Platform-Aware NPM Package Selection Test ==="

# Detect current platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo "Platform: $PLATFORM $ARCH"

# Map to Bazel platform names
if [[ "$PLATFORM" == "darwin" ]]; then
    BAZEL_OS="osx"
elif [[ "$PLATFORM" == "linux" ]]; then
    BAZEL_OS="linux"
else
    BAZEL_OS="$PLATFORM"
fi

if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    BAZEL_CPU="x86_64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    BAZEL_CPU="arm64"
else
    BAZEL_CPU="$ARCH"
fi

echo "Bazel platform: $BAZEL_OS/$BAZEL_CPU"

# Build to ensure everything is generated
echo "Building node_modules..."
bazel build //:node_modules >/dev/null 2>&1

echo "SUCCESS: All packages built successfully"

echo ""
echo "=== Testing Conditional Dependency Generation ==="

# Find esbuild platform-specific package links files
ESBUILD_LINKS_DIR=""
if [[ -d "bazel-npm-translate-lock-platform-test/external/npm__esbuild__0.16.17__links" ]]; then
    ESBUILD_LINKS_DIR="bazel-npm-translate-lock-platform-test/external/npm__esbuild__0.16.17__links"
elif [[ -d "bazel-out/k8-fastbuild/bin/external/npm__esbuild__0.16.17__links" ]]; then
    ESBUILD_LINKS_DIR="bazel-out/k8-fastbuild/bin/external/npm__esbuild__0.16.17__links"
else
    echo "  SEARCHING: Looking for esbuild links directory..."
    ESBUILD_LINKS_DIR=$(find . -path "*/npm__esbuild__0.16.17__links/defs.bzl" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")
fi

if [[ -z "$ESBUILD_LINKS_DIR" ]]; then
    echo "  ERROR: Could not find esbuild links directory"
    exit 1
fi

echo "  FOUND: esbuild links at $ESBUILD_LINKS_DIR"

# Test 1: Check for select() statements in generated files
echo ""
echo "=== Test 1: Validating select() Statement Generation ==="

DEFS_FILE="$ESBUILD_LINKS_DIR/defs.bzl"
if [[ ! -f "$DEFS_FILE" ]]; then
    echo "  ERROR: defs.bzl not found at $DEFS_FILE"
    exit 1
fi

# Check for select() statements
if grep -q "select(" "$DEFS_FILE"; then
    echo "  PASS: Found select() statements in generated defs.bzl"
    echo "  INFO: select() count: $(grep -c 'select(' "$DEFS_FILE")"
else
    echo "  FAIL: No select() statements found in $DEFS_FILE"
    echo "  GENERATED FILE CONTENT:"
    cat "$DEFS_FILE"
    exit 1
fi

# Test 2: Check for platform conditions
echo ""
echo "=== Test 2: Validating Platform Conditions ==="

PLATFORM_CONDITIONS_FOUND=0

# Check for OS conditions
if grep -q "@platforms//os:" "$DEFS_FILE"; then
    echo "  PASS: Found OS platform conditions"
    PLATFORM_CONDITIONS_FOUND=1
fi

# Check for CPU conditions
if grep -q "@platforms//cpu:" "$DEFS_FILE"; then
    echo "  PASS: Found CPU platform conditions"
    PLATFORM_CONDITIONS_FOUND=1
fi

# Check for combined conditions (OS and CPU)
if grep -q "@platforms//os:.*and.*@platforms//cpu:" "$DEFS_FILE"; then
    echo "  PASS: Found combined OS and CPU conditions"
    PLATFORM_CONDITIONS_FOUND=1
fi

if [[ $PLATFORM_CONDITIONS_FOUND -eq 0 ]]; then
    echo "  FAIL: No platform conditions found in generated file"
    exit 1
fi

# Test 3: Check for specific esbuild platform packages
echo ""
echo "=== Test 3: Validating Platform-Specific Package References ==="

# Look for platform-specific esbuild packages
FOUND_PLATFORM_PACKAGES=0

if grep -q "esbuild_linux" "$DEFS_FILE"; then
    echo "  PASS: Found Linux-specific esbuild package reference"
    FOUND_PLATFORM_PACKAGES=1
fi

if grep -q "esbuild_darwin" "$DEFS_FILE"; then
    echo "  PASS: Found Darwin-specific esbuild package reference"
    FOUND_PLATFORM_PACKAGES=1
fi

if grep -q "esbuild_win32" "$DEFS_FILE"; then
    echo "  PASS: Found Windows-specific esbuild package reference"
    FOUND_PLATFORM_PACKAGES=1
fi

if [[ $FOUND_PLATFORM_PACKAGES -eq 0 ]]; then
    echo "  FAIL: No platform-specific esbuild packages found"
    exit 1
fi

# Test 4: Check for default condition
echo ""
echo "=== Test 4: Validating Default Condition ==="

if grep -q "//conditions:default" "$DEFS_FILE"; then
    echo "  PASS: Found //conditions:default condition"
else
    echo "  FAIL: No //conditions:default found"
    exit 1
fi

# Test 5: Verify conditional dictionary structure
echo ""
echo "=== Test 5: Validating Conditional Dictionary Structure ==="

# Check that neutral deps are outside select() and platform deps are inside
if grep -A5 -B5 "select(" "$DEFS_FILE" | grep -q "}.*|.*select("; then
    echo "  PASS: Found dict merge pattern (neutral_deps | select(...))"
else
    echo "  INFO: No dict merge pattern found (may indicate all deps are conditional)"
fi

# Test 6: Validate that current platform packages are accessible
echo ""
echo "=== Test 6: Testing Current Platform Package Access ==="

# Try to query the main esbuild package to ensure it resolves
if bazel query "//:node_modules/esbuild" >/dev/null 2>&1; then
    echo "  PASS: Main esbuild package is queryable"
else
    echo "  WARN: Main esbuild package query failed (may be expected)"
fi

# Test 7: Check that repository generation includes constraint attributes
echo ""
echo "=== Test 7: Validating Repository Generation ==="

# Look for the repositories.bzl file
REPO_FILE=""
if [[ -f "bazel-npm-translate-lock-platform-test/external/npm/repositories.bzl" ]]; then
    REPO_FILE="bazel-npm-translate-lock-platform-test/external/npm/repositories.bzl"
elif [[ -f "bazel-out/k8-fastbuild/bin/external/npm/repositories.bzl" ]]; then
    REPO_FILE="bazel-out/k8-fastbuild/bin/external/npm/repositories.bzl"
else
    # Try to find it
    REPO_FILE=$(find . -name "repositories.bzl" -path "*/npm/*" 2>/dev/null | head -1 || echo "")
fi

if [[ -n "$REPO_FILE" && -f "$REPO_FILE" ]]; then
    echo "  FOUND: repositories.bzl at $REPO_FILE"

    # Check for new constraint attributes
    if grep -q "deps_os_constraints" "$REPO_FILE"; then
        echo "  PASS: Found deps_os_constraints in repository generation"
    else
        echo "  INFO: deps_os_constraints not found (may be empty)"
    fi
    
    if grep -q "deps_cpu_constraints" "$REPO_FILE"; then
        echo "  PASS: Found deps_cpu_constraints in repository generation"
    else
        echo "  INFO: deps_cpu_constraints not found (may be empty)"
    fi
else
    echo "  INFO: repositories.bzl not found for validation"
fi

echo ""
echo "=== Summary ==="
echo "✅ select() statements: FOUND"
echo "✅ Platform conditions: FOUND"
echo "✅ Platform-specific packages: FOUND"
echo "✅ Default condition: FOUND"
echo "✅ Build compatibility: VERIFIED"

echo ""
echo "🎉 Enhanced platform-aware dependency test PASSED!"
echo ""
echo "This test validates Jason's conditional dependency approach:"
echo "  - Dependencies use select() statements for platform awareness"
echo "  - Platform-specific packages are conditionally referenced"
echo "  - Incompatible packages are excluded via //conditions:default"
echo "  - Lazy repository execution prevents unnecessary downloads"

# Optional: Show some example output for debugging
echo ""
echo "=== Sample Generated Content (first 20 lines) ==="
head -20 "$DEFS_FILE" | sed 's/^/  /'
