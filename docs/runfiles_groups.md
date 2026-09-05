# Runfiles groups

`js_binary`, `js_test`, `js_library`, npm store/link producers, and the proto aspect can emit
[`RunfilesGroupInfo`](https://github.com/bazel-contrib/rules_runfiles_group)
so a packager can split the executable's runfiles without flattening the graph at analysis.

This is **off by default**. Enable it with:

```
--@rules_runfiles_group//runfiles_group:enabled=true
```

When disabled, those rules emit no grouping providers and do no grouping-only allocations.
Existing runfiles, actions, and `JsInfo` are unchanged.

## Group policy

Named groups use the `aspect_rules_js#` prefix:

| Name | Contents |
| --- | --- |
| `aspect_rules_js#node` | Selected Node binary |
| `aspect_rules_js#runtime_support` | Platform node wrapper, fs patches, bootstrap, coverage bootstrap |
| `aspect_rules_js#npm` | npm wrapper and toolchain npm sources when `include_npm=True` |
| `aspect_rules_js#coverage` | Coverage report program when the existing coverage predicates include it |

Per-target groups are named with the producing target's `Label`: the binary's launchers and copied
application files, each `js_library`'s owned outputs, each npm store's package directory and
internal links, and each root-link's `node_modules/<pkg>` and `.bin` scripts.

Imported npm stores are `third_party` at shared-deps rank. Workspace-local stores and first-party
libraries/binaries are `first_party`. Manually declared stores without a known generation path stay
unspecified.

## Companion channels

`JsRunfilesGroupsInfo` (`@aspect_rules_js//js:runfiles_groups.bzl`) describes selectable *file*
channels (`sources`, `types`, npm, store files). It is not a substitute for `RunfilesGroupInfo`.
A library's public `RunfilesGroupInfo` matches `DefaultInfo.default_runfiles` only — not the full
`JsInfo` closure.

Downstream `JsInfo` producers should merge `js_runfiles_groups.RULE_ATTRS`, gate on
`js_runfiles_groups.is_enabled(ctx)`, and emit companion entries with `runfiles_groups.entry`.

Packagers must not evaluate `aspect_hints` in producer rules. A consuming rule should attach an
aspect that forwards `aspect_hints` and call `runfiles_groups.resolve` once. When grouping is
disabled, `resolve` returns `None` and the consumer should use `DefaultInfo.default_runfiles`.

## Foreign overlap

Native rules_js graphs are required to be overlap-free after name folding. Opaque foreign
producers may overlap; packagers should use `overlapping_group_behavior = "warn"` at those
boundaries. Do not globally ignore overlap or subtract files to hide it.

`js_image_layer` is unchanged. Migrating it to the consumer API is a separate change.
