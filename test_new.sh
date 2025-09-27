#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

echo "=== Platform-Aware NPM Package Selection Test ==="

# Detect current platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names to match Node.js naming
case $ARCH in
    "x86_64") NODE_ARCH="x64" ;;
    "aarch64") NODE_ARCH="arm64" ;;
    "arm64") NODE_ARCH="arm64" ;;
    *) NODE_ARCH="$ARCH" ;;
esac

# Normalize platform names to match Node.js naming  
case $PLATFORM in
    "darwin") NODE_PLATFORM="darwin" ;;
    "linux") NODE_PLATFORM="linux" ;;
    *) NODE_PLATFORM="$PLATFORM" ;;
esac

echo "Platform: $PLATFORM $ARCH"
echo "Node.js platform: ${NODE_PLATFORM}_${NODE_ARCH}"

# Build first to ensure bazel-out directory exists
echo "Building node_modules..."
bazel build //:node_modules >/dev/null 2>&1

# Find the bazel-out directory structure
BAZEL_OUT_DIR=""
for potential_dir in "bazel-out/k8-fastbuild" "bazel-out/${NODE_PLATFORM}_${NODE_ARCH}-fastbuild" "bazel-out/${NODE_PLATFORM}-${NODE_ARCH}-fastbuild" "bazel-out/${NODE_PLATFORM}_${NODE_ARCH}-opt" "bazel-out/darwin_arm64-fastbuild"; do
    if [[ -d "$potential_dir" ]]; then
        BAZEL_OUT_DIR="$potential_dir"
        break
    fi
done

if [[ -z "$BAZEL_OUT_DIR" ]]; then
    echo "ERROR: Could not find bazel-out directory"
    echo "Available bazel-out directories:"
    ls -la bazel-out/ 2>/dev/null || echo "No bazel-out directory found"
    exit 1
fi

echo "Found bazel-out directory: $BAZEL_OUT_DIR"

# Function to check if a package repository directory exists (they should ALL exist now)
check_package_repository_exists() {
    local package_name="$1"
    
    # Check if repository directory exists in bazel-out
    local repo_path="$BAZEL_OUT_DIR/bin/external/npm__esbuild_${package_name}__0.16.17"
    local package_store_path="$BAZEL_OUT_DIR/bin/node_modules/.aspect_rules_js/@esbuild+${package_name}@0.16.17"
    
    local repo_exists="false"
    local package_exists="false"
    
    if [[ -d "$repo_path" ]]; then
        repo_exists="true"
    fi
    
    if [[ -d "$package_store_path" ]]; then
        package_exists="true"
    fi
    
    # All packages should exist now (but conditionally work via select())
    if [[ "$repo_exists" = "true" || "$package_exists" = "true" ]]; then
        echo "  PASS: $package_name repository exists (as expected with select() approach)"
        return 0
    else
        echo "  FAIL: $package_name repository missing"
        return 1
    fi
}

# Function to check that the current platform's compatible package works
check_platform_compatible_package_works() {
    local current_platform_package="${NODE_PLATFORM}-${NODE_ARCH}"
    echo "Testing that compatible package ($current_platform_package) works correctly..."
    
    # Try to build specifically the compatible package to ensure it works
    if bazel build "//node_modules/@esbuild/${current_platform_package}" >/dev/null 2>&1; then
        echo "  PASS: Compatible package @esbuild/${current_platform_package} builds successfully"
        return 0
    else
        echo "  FAIL: Compatible package @esbuild/${current_platform_package} failed to build"
        return 1
    fi
}

# Function to check generated repositories.bzl file (all packages should be present now)
check_repositories_bzl() {
    # Look for the generated repositories file
    local repos_file=""
    for potential_file in "bazel-bin/external/npm/repositories.bzl" "bazel-out/*/bin/external/npm/repositories.bzl"; do
        if [[ -f "$potential_file" ]]; then
            repos_file="$potential_file"
            break
        fi
    done
    
    if [[ -z "$repos_file" ]]; then
        echo "WARNING: Could not find repositories.bzl file"
        return 0
    fi
    
    # Count npm_import rules for platform-specific packages - should find all of them now
    local expected_packages=("linux-x64" "darwin-arm64" "win32-x64" "android-arm64")
    local found_count=0
    
    for package in "${expected_packages[@]}"; do
        if grep -q "npm__esbuild_${package}__" "$repos_file"; then
            echo "  PASS: Found npm_import rule for $package (as expected with select() approach)"
            found_count=$((found_count + 1))
        else
            echo "  FAIL: Missing npm_import rule for $package"
        fi
    done
    
    if [[ "$found_count" -eq "${#expected_packages[@]}" ]]; then
        echo "PASS: All expected npm_import rules found in repositories.bzl"
        return 0
    else
        echo "FAIL: Found $found_count/${#expected_packages[@]} expected npm_import rules"
        return 1
    fi
}

# Function to test that esbuild main package works (this should work regardless of platform)
test_main_esbuild_package() {
    echo "Testing that main esbuild package works..."
    if bazel build "//node_modules/esbuild" >/dev/null 2>&1; then
        echo "  PASS: Main esbuild package builds successfully"
        return 0
    else
        echo "  FAIL: Main esbuild package failed to build"
        return 1
    fi
}

# Main test logic - with select() approach, all packages should exist
echo "Running platform-aware package validation..."

success=true

# Test that all major platform packages exist (they should with select() approach)
echo "Checking that all platform-specific packages are generated..."
for package in "linux-x64" "darwin-arm64" "win32-x64" "android-arm64" "freebsd-x64"; do
    if ! check_package_repository_exists "$package"; then
        success=false
    fi
done

# Test that the current platform's compatible package actually works
if ! check_platform_compatible_package_works; then
    success=false
fi

# Test that the main esbuild package works
if ! test_main_esbuild_package; then
    success=false
fi

# Check the generated repositories.bzl file
if ! check_repositories_bzl; then
    success=false
fi

# Test basic require functionality
echo "Testing basic Node.js require functionality..."
if node basic_require_test.js; then
    echo "  PASS: Basic require test passed"
else
    echo "  FAIL: Basic require test failed"
    success=false
fi

# Final result
echo ""
if [[ "$success" = "true" ]]; then
    echo "PASS: Platform-aware package selection test passed"
    echo "NOTE: This test validates Jason's approach where all packages are generated"
    echo "      but platform compatibility is handled via select() statements."
    exit 0
else
    echo "FAIL: Platform-aware package selection test failed"
    exit 1
fi 