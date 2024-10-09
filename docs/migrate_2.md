# Migrating from rules_js 1.x to rules_js 2.0

The 2.0 release is our first major release, where we've made breaking changes to keep the codebase healthy and adaptable to users needs. We expect to make major releases no more frequently than yearly.

Users of rules_js 1.x should expect a fairly small effort required to migrate.

You can follow the link to each rules_js pull request in the notes below.
In many cases, updates to the testing folders (`e2e` or `examples`) are illustrative of the changes required.

## Dependency versions

Bazel 5 is no longer supported. Users must upgrade to Bazel 6 or greater. ([#1589](https://github.com/aspect-build/rules_js/pull/1589)), ([#1610](https://github.com/aspect-build/rules_js/pull/1610))

Minimum dependency versions have been increased:

- `rules_nodejs`  6.1.0 ([#1579](https://github.com/aspect-build/rules_js/pull/1579))
- `aspect_bazel_lib` 2.7.1 ([#1580](https://github.com/aspect-build/rules_js/pull/1580))

## User facing changes

Any rules_js user is likely to encounter these changes which require some edits to your code.

### npm_translate_lock

The default label used to link a package has changed to `pkg` ([#1684](https://github.com/aspect-build/rules_js/pull/1684)).
You can change your `npm_package` rules to have `name = 'pkg'`, see [examples](https://github.com/aspect-build/rules_js/pull/1684/files#diff-d13f73189fcb63af69a6bfa0eb9cb61e71d6466d2eac4c1051674b73976a1cfe).
Alternatively, set the attribute [`npm_package_target_name`](https://docs.aspect.build/rulesets/aspect_rules_js/docs/npm_translate_lock/#npm_package_target_name) back to match the folder name to restore the rules_js 1.0 behavior where `{dirname}` was the default.

The `update_pnpm_lock` default value is now `False` rather than based on presence of `npm_package_lock` or `yarn_lock`. ([#1624](https://github.com/aspect-build/rules_js/pull/1624))

Deprecated attributes have been removed from the repository rule:
- `warn_on_unqualified_tarball_url` ([#1568](https://github.com/aspect-build/rules_js/pull/1568))
- `package_json` ([#1569](https://github.com/aspect-build/rules_js/pull/1569))
- `update_pnpm_lock_node_toolchain_prefix` ([#1574](https://github.com/aspect-build/rules_js/pull/1574))
- `use_starlark_yaml_parser` ([#1658](https://github.com/aspect-build/rules_js/pull/1658))

And one attribute from the module extension used in `MODULE.bazel`:
- `pnpm_version` ([#1576](https://github.com/aspect-build/rules_js/pull/1576))

### npm_package

The `npm_package#include_runfiles` attribute allows a package to ship with the default runfiles produced by the `srcs`.
The default is now `False` ([#1567](https://github.com/aspect-build/rules_js/pull/1567)).

You may need to set it back to `True` in a few cases:

- to work-around issues with rules that don't provide everything needed in the `JsInfo` fields (`sources`, `transitive_sources`, `types` & `transitive_types`)
- to depend on the runfiles targets that don't use `JsInfo`

### npm_import

Two deprecated attributes were removed:
- `run_lifecycle_hooks` ([#1572](https://github.com/aspect-build/rules_js/pull/1572))
- `lifecycle_hooks_no_sandbox` ([#1573](https://github.com/aspect-build/rules_js/pull/1573))

### js_filegroup

`js_filegroup` has been renamed to `js_info_files` ([#1615](https://github.com/aspect-build/rules_js/pull/1615))

It also has two new attributes, `include_sources` and `include_transitive_declarations`. These are used by helpers `gather_files_from_js_providers` + `gather_runfiles` ([#1585](https://github.com/aspect-build/rules_js/pull/1585))

### declarations => types 

The term `declarations` has been renamed to `types` in `JsInfo` & throughout rules_js ([#1619](https://github.com/aspect-build/rules_js/pull/1619))

### WORKSPACE

The `nodejs_register_toolchains()` helper has been replaced by a new `rules_js_register_toolchains` WORKSPACE function ([#1593](https://github.com/aspect-build/rules_js/pull/1593)).
See [examples](https://github.com/aspect-build/rules_js/pull/1593/files#diff-c808f5893f0766a46d39f5b1ff8b3cbeb5eb3cadef752af39a56ab65f1c92c93)

The deprecated `//npm:npm_import.bzl` helper has been removed. ([#1570](https://github.com/aspect-build/rules_js/pull/1570))

### Other

The `expand_template` rule is removed, we recommend the [alternative in bazel-lib](https://docs.aspect.build/rulesets/aspect_bazel_lib/docs/expand_template/) ([#1587](https://github.com/aspect-build/rules_js/pull/1587))

`js_binary`, `js_test` and `js_run_binary` have new attributes `include_sources` and `include_transitive_types`. (https://github.com/aspect-build/rules_js/commit/9b1d03c23519e6d47c59687be7f8e2327e85a931)

## Internal changes

These changes aren't visible to end-users.
However if you have written your own custom rules based on rules_js, changes may be required in those rules.

### js_binary

- refactor: make internal `unresolved_symlinks_enabled` attribute of `js_binary` mandatory ([#1571](https://github.com/aspect-build/rules_js/pull/1571))

### NpmPackageInfo

- refactor: rename `directory` attribute of `NpmPackageInfo` to `src` ([#1575](https://github.com/aspect-build/rules_js/pull/1575))

### NpmPackageStoreInfo

- refactor: don't gather files from `NpmPackageStoreInfo` providers in `gather_files_from_js_info` ([#1663](https://github.com/aspect-build/rules_js/pull/1663))
- refactor: remove unused `src_directory` from `NpmPackageStoreInfo` ([#1566](https://github.com/aspect-build/rules_js/pull/1566))

### JsInfo

- refactor: rename `JsInfo` `npm_package_store_deps` to `npm_package_store_infos` ([#1620](https://github.com/aspect-build/rules_js/pull/1620))
- refactor: rename `include_npm_linked_packages` to `include_npm_sources` && JsInfo `npm_linked_packages` to `npm_sources` ([#1623](https://github.com/aspect-build/rules_js/pull/1623))
- refactor: rename `declarations` to `types` in JsInfo & throughout rules_js ([#1619](https://github.com/aspect-build/rules_js/pull/1619))
- refactor: re-order fields in `JsInfo` for readability ([#1648](https://github.com/aspect-build/rules_js/pull/1648))

### Other

- refactor: rename `gather_files_from_js_providers` to `gather_files_from_js_infos` ([#1617](https://github.com/aspect-build/rules_js/pull/1617), [#1665](https://github.com/aspect-build/rules_js/pull/1665))
- refactor: remove `utils.home_directory` and use `get_home_directory` from Aspect bazel-lib utils instead ([#1606](https://github.com/aspect-build/rules_js/pull/1606))
- refactor: remove `//js:enable_runfiles` and use `@aspect_bazel_lib//lib:enable_runfiles` instead ([#1605](https://github.com/aspect-build/rules_js/pull/1605))
- fix: drop `.sh` extension from `js_binary`, `merger` and `js_image_layer` launchers ([#1586](https://github.com/aspect-build/rules_js/pull/1586))
- refactor: remove unused `NpmLinkedPackageInfo` provider and corresponding unused `npm_linked_packages` from JsInfo; rename load bearing `npm_linked_package_files` to `npm_linked_packages` ([#1588](https://github.com/aspect-build/rules_js/pull/1588))
- refactor: remove deprecated `//js/private:enable_runfiles` and `//js/private:experimental_allow_unresolved_symlinks` ([#1577](https://github.com/aspect-build/rules_js/pull/1577))
- refactor: remove `JS_LIBRARY_DATA_ATTR` and `DOWNSTREAM_LINKED_NPM_DEPS_DOCSTRING` from js_helpers
