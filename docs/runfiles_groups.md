# Runfiles groups

`js_binary`, `js_test`, `js_library`, and npm store/link producers can emit
[`RunfilesGroupInfo`](https://github.com/bazel-contrib/rules_runfiles_group)
describing the admitted runtime closure. Grouping is metadata only: it does not
change copying, launchers, `JsInfo`, or execution.

This is **off by default**. Enable it with:

```
--@rules_runfiles_group//runfiles_group:enabled=true
```

When disabled, those rules emit no grouping providers and do no grouping-only
work. `RunfilesGroupInfo` is the only new production provider.

## Classification

Libraries do not put JsInfo-only sources on `RunfilesGroupInfo`. Those files are
classified when a `js_binary` / `js_test` admits them. The public provider always
equals `DefaultInfo.default_runfiles` in all four runfiles components.

Named groups use the `aspect_rules_js#` prefix and `merge_affinity = "aspect_rules_js"`:

| Name | Role | Rank | Merge |
| --- | --- | ---: | --- |
| target `Label` | Protected application (launcher, entry point, ordinary raw `data` sources) | 0 | `do_not_merge=True` |
| `aspect_rules_js#first_party` | Source-backed JS and generated ordinary data | -50 | mergeable |
| `aspect_rules_js#third_party` | Packaged npm payloads (`NpmPackageInfo` / store directories) | -100 | mergeable |
| `aspect_rules_js#npm_links` | Root links and known `.bin` shims | -200 | mergeable |
| `aspect_rules_js#npm` | Coarse npm inventory at a link; **absent** from normalized binaries | -200 | mergeable |
| `aspect_rules_js#node` | Admitted Node executable File | -1000 | mergeable |
| `aspect_rules_js#node_external:<label>` | Path-only Node marker (empty files) | -1000 | `do_not_merge=True` |
| `aspect_rules_js#runtime_support` | Launcher wrapper, fs patches, bootstrap | -900 | mergeable |
| `aspect_rules_js#npm_toolchain` | `include_npm` toolchain inventory | -900 | mergeable |
| `aspect_rules_js#unclassified` | Admitted leftovers with no known role | -300 | mergeable |

Classification follows the **representation visible at admission**, not package
history. A source-backed library in an external repository is first-party. A
locally built `npm_package` consumed through the store/link API is third-party.
Wrapping `npm_package` in `js_library(srcs = ...)` exposes a generated source
tree and is first-party; that loss of npm provenance is intentional.

`js_proto_aspect` remains JsInfo-only. Generated JS admitted by a downstream
`js_binary` is first-party; that path is tested in `//js/private/test/proto`.

Same-name folding unions File identities. It does not prove that two distinct
Files are equivalent packages.

## Downstream producers

`RunfilesGroupInfo` is the only grouping provider. A derivative that changes
default runfiles after `js_binary_lib.implementation` must rebuild
`RunfilesGroupInfo`. `js_image_layer` is unchanged. Packaging, relocation, and
byte-dedup are consumer work, not part of this producer.
