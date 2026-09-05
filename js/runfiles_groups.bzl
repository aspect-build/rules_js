"""Public API for optional RunfilesGroupInfo / JsRunfilesGroupsInfo participation.

Downstream JsInfo producers that want fine-grained grouping should merge
`js_runfiles_groups.RULE_ATTRS` into their rule attrs, gate work on
`js_runfiles_groups.is_enabled(ctx)`, and emit `JsRunfilesGroupsInfo` for
selectable file channels. Public runtime groups belong on `RunfilesGroupInfo`
and must equal `DefaultInfo.default_runfiles`.

Enable globally with `--@rules_runfiles_group//runfiles_group:enabled`.
"""

load(
    "//js/private:js_runfiles_groups.bzl",
    _JsRunfilesGroupsInfo = "JsRunfilesGroupsInfo",
    _js_runfiles_groups = "js_runfiles_groups",
)

JsRunfilesGroupsInfo = _JsRunfilesGroupsInfo
js_runfiles_groups = _js_runfiles_groups
