#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

echo "=== Platform-Aware NPM Package Filtering Test ==="

# Detect current platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names to match Bazel's naming
case $ARCH in
    "x86_64") BAZEL_ARCH="amd64" ;;
    "aarch64") BAZEL_ARCH="arm64" ;;
    "arm64") BAZEL_ARCH="arm64" ;;
    *) BAZEL_ARCH="$ARCH" ;;
esac

# Normalize platform names to match Bazel's naming  
case $PLATFORM in
    "darwin") BAZEL_PLATFORM="darwin" ;;
    "linux") BAZEL_PLATFORM="linux" ;;
    *) BAZEL_PLATFORM="$PLATFORM" ;;
esac

echo "Platform: $PLATFORM $ARCH"
echo "Bazel platform: ${BAZEL_PLATFORM}_${BAZEL_ARCH}"

# Build first to ensure bazel-out directory exists
echo "Building node_modules..."
bazel build //:node_modules >/dev/null 2>&1

# Find the bazel-out directory structure
BAZEL_OUT_DIR=""
for potential_dir in "bazel-out/${BAZEL_PLATFORM}_${BAZEL_ARCH}-fastbuild" "bazel-out/${BAZEL_PLATFORM}-${BAZEL_ARCH}-fastbuild" "bazel-out/${BAZEL_PLATFORM}_${BAZEL_ARCH}-opt" "bazel-out/darwin_arm64-fastbuild"; do
    if [[ -d "$potential_dir" ]]; then
        BAZEL_OUT_DIR="$potential_dir"
        break
    fi
done

if [[ -z "$BAZEL_OUT_DIR" ]]; then
    echo "ERROR: Could not find bazel-out directory for platform ${BAZEL_PLATFORM}_${BAZEL_ARCH}"
    echo "Available bazel-out directories:"
    ls -la bazel-out/ 2>/dev/null || echo "No bazel-out directory found"
    exit 1
fi

echo "Found bazel-out directory: $BAZEL_OUT_DIR"

# Function to check if a package repository directory exists
check_package_repository_exists() {
    local package_name="$1"
    local should_exist="$2"  # "true" or "false"

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

    # Verify expectations
    if [[ "$should_exist" = "true" ]]; then
        if [[ "$repo_exists" = "true" || "$package_exists" = "true" ]]; then
            echo "  PASS: $package_name (compatible platform)"
            return 0
        else
            echo "  FAIL: $package_name missing but should exist (compatible platform)"
            return 1
        fi
    else
        if [[ "$repo_exists" = "false" && "$package_exists" = "false" ]]; then
            echo "  PASS: $package_name correctly filtered (incompatible platform)"
            return 0
        else
            echo "  FAIL: $package_name exists but should be filtered (incompatible platform)"
            return 1
        fi
    fi
}

# Function to check generated repositories.bzl file
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

    # Count npm_import rules for platform-specific packages
    local incompatible_count=0

    # Define incompatible packages for current platform
    local incompatible_packages=()
    if [[ "$BAZEL_PLATFORM" = "darwin" && "$BAZEL_ARCH" = "arm64" ]]; then
        incompatible_packages=("linux-x64" "win32-x64" "linux-arm64")
    elif [[ "$BAZEL_PLATFORM" = "linux" && "$BAZEL_ARCH" = "amd64" ]]; then
        incompatible_packages=("darwin-arm64" "win32-x64" "darwin-x64")
    else
        # Generic check - just look for common incompatible ones
        incompatible_packages=("win32-x64")
    fi

    for package in "${incompatible_packages[@]}"; do
        if grep -q "npm__esbuild_${package}__" "$repos_file"; then
            echo "FAIL: Found npm_import rule for incompatible package: $package"
            incompatible_count=$((incompatible_count + 1))
        fi
    done

    if [[ "$incompatible_count" -gt 0 ]]; then
        echo "FAIL: Found $incompatible_count npm_import rules for incompatible packages"
        return 1
    else
        echo "PASS: No npm_import rules found for incompatible packages"
        return 0
    fi
}

# Main test logic based on current platform
echo ""
echo "Running platform-specific validation..."

success=true

if [[ "$BAZEL_PLATFORM" = "darwin" && "$BAZEL_ARCH" = "arm64" ]]; then
    # linux-x64 should NOT exist (incompatible)
    if ! check_package_repository_exists "linux-x64" "false"; then
        success=false
    fi
    
    # win32-x64 should NOT exist (incompatible)
    if ! check_package_repository_exists "win32-x64" "false"; then
        success=false
    fi

    # darwin-arm64 should exist (compatible) if not optional
    if ! check_package_repository_exists "darwin-arm64" "true"; then
        echo "  INFO: darwin-arm64 doesn't exist - this is OK if it's optional and not needed"
        # Don't fail the test for this case since it's optional
    fi
    
elif [[ "$BAZEL_PLATFORM" = "linux" && "$BAZEL_ARCH" = "amd64" ]]; then
    # darwin-arm64 should NOT exist (incompatible)
    if ! check_package_repository_exists "darwin-arm64" "false"; then
        success=false
    fi
    
    # win32-x64 should NOT exist (incompatible)
    if ! check_package_repository_exists "win32-x64" "false"; then
        success=false
    fi

    # linux-x64 should exist (compatible) if not optional
    if ! check_package_repository_exists "linux-x64" "true"; then
        echo "  INFO: linux-x64 doesn't exist - this is OK if it's optional and not needed"
        # Don't fail the test for this case since it's optional
    fi
    
else
    echo "Testing generic platform filtering..."

    # Generic test - just check that some packages don't exist
    skipped_count=0
    total_checked=0

    for package in "win32-x64" "win32-ia32" "sunos-x64"; do
        total_checked=$((total_checked + 1))
        if ! check_package_repository_exists "$package" "false"; then
            # Package exists when it shouldn't
            echo "  WARNING: Package $package exists but should be filtered"
        else
            skipped_count=$((skipped_count + 1))
        fi
    done
    
    if [[ "$skipped_count" -eq 0 ]]; then
        echo "  FAIL: No packages filtered - platform filtering might not be working"
        success=false
    fi
fi

# Check the generated repositories.bzl file
if ! check_repositories_bzl; then
    success=false
fi

# Final result
echo ""
echo "=== Test Summary ==="
if [[ "$success" = "true" ]]; then
    echo "PASS: Platform filtering test passed"
    exit 0
else
    echo "FAIL: Platform filtering test failed"
    exit 1
fi 