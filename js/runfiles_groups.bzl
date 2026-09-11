"""Public API for optional RunfilesGroupInfo participation.

`RunfilesGroupInfo` is the only new producer provider. It is the interoperability
contract: grouping and merge policy.

Downstream rules that emit `JsInfo` and want grouping should merge
`js_runfiles_groups.RULE_ATTRS` into their rule attrs, gate work on
`js_runfiles_groups.is_enabled(ctx)`, and put admitted default runfiles on
`RunfilesGroupInfo`. Those groups must equal `DefaultInfo.default_runfiles`.

Enable globally with `--@rules_runfiles_group//runfiles_group:enabled`.
"""

load(
    "//js/private:js_runfiles_groups.bzl",
    _js_runfiles_groups = "js_runfiles_groups",
)

js_runfiles_groups = struct(
    RULE_ATTRS = _js_runfiles_groups.RULE_ATTRS,
    is_enabled = _js_runfiles_groups.is_enabled,
    AFFINITY = _js_runfiles_groups.AFFINITY,
    FIRST_PARTY_GROUP = _js_runfiles_groups.FIRST_PARTY_GROUP,
    THIRD_PARTY_GROUP = _js_runfiles_groups.THIRD_PARTY_GROUP,
    NPM_GROUP = _js_runfiles_groups.NPM_GROUP,
    NPM_LINKS_GROUP = _js_runfiles_groups.NPM_LINKS_GROUP,
    NODE_GROUP = _js_runfiles_groups.NODE_GROUP,
    NODE_EXTERNAL_PREFIX = _js_runfiles_groups.NODE_EXTERNAL_PREFIX,
    RUNTIME_SUPPORT_GROUP = _js_runfiles_groups.RUNTIME_SUPPORT_GROUP,
    NPM_TOOLCHAIN_GROUP = _js_runfiles_groups.NPM_TOOLCHAIN_GROUP,
    COVERAGE_GROUP = _js_runfiles_groups.COVERAGE_GROUP,
    UNCLASSIFIED_GROUP = _js_runfiles_groups.UNCLASSIFIED_GROUP,
    RANK_FIRST_PARTY_DEPS = _js_runfiles_groups.RANK_FIRST_PARTY_DEPS,
    RANK_NPM_LINKS = _js_runfiles_groups.RANK_NPM_LINKS,
    RANK_UNCLASSIFIED = _js_runfiles_groups.RANK_UNCLASSIFIED,
    RANK_BOOTSTRAP = _js_runfiles_groups.RANK_BOOTSTRAP,
    RANK_EXECUTABLE = _js_runfiles_groups.RANK_EXECUTABLE,
    RANK_FOUNDATION = _js_runfiles_groups.RANK_FOUNDATION,
    RANK_SHARED_DEPS = _js_runfiles_groups.RANK_SHARED_DEPS,
)
