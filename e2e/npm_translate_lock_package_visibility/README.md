# Test coverage for package_visibility enforcement in npm_translate_lock

This test validates that `package_visibility` restrictions are properly enforced for workspace packages when using local node_modules references (`:node_modules/package`).

## Bug Description

Previously, workspace packages could bypass `package_visibility` restrictions by referencing packages locally (`:node_modules/some-dep`) instead of from the root (`//:node_modules/some-dep`). This security issue allowed unauthorized access to restricted packages.

## Test Validation

The test attempts to build `//packages/from-local:from_local_lib` which references `:node_modules/some-dep` locally. This should fail with a visibility error because `some-dep` is restricted to `//packages/from-root:__subpackages__` only.

## Expected Behavior

With the fix, local references create aliases that delegate to root targets, ensuring Bazel's visibility system is properly enforced regardless of reference style.