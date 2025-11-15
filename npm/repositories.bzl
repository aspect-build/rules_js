"""Repository rules to fetch third-party npm packages"""

load("//npm/private:npm_import.bzl", _npm_import = "npm_import")
load("//npm/private:npm_translate_lock.bzl", _list_patches = "list_patches")
load("//npm/private:pnpm_repository.bzl", _DEFAULT_PNPM_VERSION = "DEFAULT_PNPM_VERSION", _LATEST_PNPM_VERSION = "LATEST_PNPM_VERSION", _pnpm_repository = "pnpm_repository")

DEFAULT_PNPM_VERSION = _DEFAULT_PNPM_VERSION
LATEST_PNPM_VERSION = _LATEST_PNPM_VERSION

list_patches = _list_patches
npm_import = _npm_import
pnpm_repository = _pnpm_repository
