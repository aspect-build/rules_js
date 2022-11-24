"""Repository rule to fetch an npm package.

Load with,

```starlark
load("@aspect_rules_js//npm:npm_import.bzl", "npm_import")
```

[`npm_translate_lock`](./npm_translate_lock.md) is the primary user-facing API.
Advanced users may want to directly fetch a package from npm rather than start from a lockfile.
[`npm_import`](#npm_import) does this.
"""

load("//npm/private:npm_import_macro.bzl", _npm_import = "npm_import")
load(":npm_translate_lock.bzl", _npm_translate_lock = "npm_translate_lock")

npm_import = _npm_import

# TODO(2.0): remove this deprecated load point; can hoist the npm_import_macro.bzl impl to here at that point
def npm_translate_lock(**kwargs):
    """Deprecated load point for `npm_translate_lock` repository rule.

    Instead use,

    ```starlark
    load("@aspect_rules_js//npm:npm_translate_lock.bzl", "npm_translate_lock")
    ```
        **kwargs: All attributes
    """

    # buildifier: disable=print
    print("""
WARNING: `load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")` is a deprecated load point for `npm_translate_lock`.

Instead use,

    load("@aspect_rules_js//npm:npm_translate_lock.bzl", "npm_translate_lock")

""")
    _npm_translate_lock(**kwargs)
