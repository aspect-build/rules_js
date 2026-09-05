"""Consumer/hint tests: resolve through an aspect that forwards aspect_hints."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupTransformInfo")
load("//js:defs.bzl", "js_binary")

_HintsInfo = provider(doc = "Forwarded aspect_hints.", fields = ["aspect_hints"])

_ENABLED = {str(Label("@rules_runfiles_group//runfiles_group:enabled")): True}
_DISABLED = {str(Label("@rules_runfiles_group//runfiles_group:enabled")): False}

def _hints_aspect_impl(_target, ctx):
    return [_HintsInfo(aspect_hints = getattr(ctx.rule.attr, "aspect_hints", []))]

_hints_aspect = aspect(implementation = _hints_aspect_impl)

ConsumerGroupsInfo = provider(
    doc = "Resolved group names from a test packager.",
    fields = {
        "names": "list of canonical group name strings",
        "executable_group": "canonical executable group name or empty",
        "ungrouped": "True when resolve returned None",
    },
)

def _noop_transform(resolved):
    return resolved

def _rename_binary_transform(resolved):
    groups = []
    executable = resolved.executable_group
    for entry in resolved.groups:
        if entry.name == resolved.executable_group:
            entry = runfiles_groups.derive(entry, name = "renamed_binary")
            executable = "renamed_binary"
        groups.append(entry)
    return runfiles_groups.resolved(groups, executable_group = executable)

def _prefix_a_transform(resolved):
    groups = [runfiles_groups.derive(e, name = "a+" + runfiles_groups.name_str(e.name)) for e in resolved.groups]
    executable = "a+" + runfiles_groups.name_str(resolved.executable_group)
    return runfiles_groups.resolved(groups, executable_group = executable)

def _prefix_b_transform(resolved):
    groups = [runfiles_groups.derive(e, name = "b+" + runfiles_groups.name_str(e.name)) for e in resolved.groups]
    executable = "b+" + runfiles_groups.name_str(resolved.executable_group)
    return runfiles_groups.resolved(groups, executable_group = executable)

def _drop_node_transform(resolved):
    return runfiles_groups.resolved(
        [e for e in resolved.groups if runfiles_groups.name_str(e.name) != "aspect_rules_js#node"],
        executable_group = resolved.executable_group,
    )

def _protect_node_transform(resolved):
    groups = []
    for entry in resolved.groups:
        if runfiles_groups.name_str(entry.name) == "aspect_rules_js#node":
            entry = runfiles_groups.derive(entry, do_not_merge = True)
        groups.append(entry)
    return runfiles_groups.resolved(groups, executable_group = resolved.executable_group)

def _drop_executable_transform(resolved):
    return runfiles_groups.resolved(
        [e for e in resolved.groups if e.name != resolved.executable_group],
        executable_group = resolved.executable_group,
    )

_TRANSFORMS = {
    "noop": _noop_transform,
    "rename_binary": _rename_binary_transform,
    "prefix_a": _prefix_a_transform,
    "prefix_b": _prefix_b_transform,
    "drop_node": _drop_node_transform,
    "protect_node": _protect_node_transform,
    "drop_executable": _drop_executable_transform,
}

def _keyed_transform_impl(ctx):
    return [RunfilesGroupTransformInfo(transform = _TRANSFORMS[ctx.attr.transform])]

runfiles_group_hint = rule(
    implementation = _keyed_transform_impl,
    attrs = {
        "transform": attr.string(mandatory = True, values = sorted(_TRANSFORMS.keys())),
    },
)

UnrelatedHintInfo = provider(doc = "Ignored by the resolver.", fields = ["unused"])

def _unrelated_impl(_ctx):
    return [UnrelatedHintInfo(unused = True)]

unrelated_hint = rule(implementation = _unrelated_impl)

def _consume_impl(ctx):
    binary = ctx.attr.binary
    hints = binary[_HintsInfo].aspect_hints
    resolved = runfiles_groups.resolve(ctx, binary, aspect_hints = hints)
    if resolved == None:
        return [ConsumerGroupsInfo(names = ["fallback"], executable_group = "", ungrouped = True)]
    names = [runfiles_groups.name_str(g.name) for g in resolved.groups]
    exec_name = runfiles_groups.name_str(resolved.executable_group) if resolved.executable_group else ""
    return [ConsumerGroupsInfo(names = names, executable_group = exec_name, ungrouped = False)]

consume_groups = rule(
    implementation = _consume_impl,
    attrs = {
        "binary": attr.label(mandatory = True, aspects = [_hints_aspect]),
    },
)

def _consumer_names_impl(ctx):
    env = analysistest.begin(ctx)
    info = analysistest.target_under_test(env)[ConsumerGroupsInfo]
    if ctx.attr.expect_ungrouped:
        asserts.true(env, info.ungrouped)
        asserts.equals(env, ["fallback"], info.names)
        return analysistest.end(env)
    asserts.false(env, info.ungrouped)
    if ctx.attr.expect_names:
        asserts.equals(env, ctx.attr.expect_names, info.names)
    if ctx.attr.expect_executable:
        asserts.equals(env, ctx.attr.expect_executable, info.executable_group)
    if ctx.attr.expect_missing:
        for name in ctx.attr.expect_missing:
            asserts.false(env, name in info.names, "did not expect %s in %s" % (name, info.names))
    if ctx.attr.expect_contains:
        for name in ctx.attr.expect_contains:
            asserts.true(env, name in info.names, "expected %s in %s" % (name, info.names))
    return analysistest.end(env)

consumer_names_test = analysistest.make(
    _consumer_names_impl,
    attrs = {
        "expect_names": attr.string_list(),
        "expect_executable": attr.string(default = ""),
        "expect_missing": attr.string_list(),
        "expect_contains": attr.string_list(),
        "expect_ungrouped": attr.bool(default = False),
    },
    config_settings = _ENABLED,
)

consumer_disabled_test = analysistest.make(
    _consumer_names_impl,
    attrs = {
        "expect_names": attr.string_list(),
        "expect_executable": attr.string(default = ""),
        "expect_missing": attr.string_list(),
        "expect_contains": attr.string_list(),
        "expect_ungrouped": attr.bool(default = False),
    },
    config_settings = _DISABLED,
)

def _expect_failure_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "executable")
    return analysistest.end(env)

drop_executable_failure_test = analysistest.make(
    _expect_failure_impl,
    expect_failure = True,
    config_settings = _ENABLED,
)

def _hinted_binary(name, hints):
    js_binary(
        name = name,
        copy_data_to_bin = True,
        entry_point = "main.js",
        include_npm = False,
        aspect_hints = hints,
    )

def consumer_tests():
    """Hint/consumer analysis tests around :minimal."""
    runfiles_group_hint(name = "hint_noop", transform = "noop")
    runfiles_group_hint(name = "hint_rename", transform = "rename_binary")
    runfiles_group_hint(name = "hint_prefix_a", transform = "prefix_a")
    runfiles_group_hint(name = "hint_prefix_b", transform = "prefix_b")
    runfiles_group_hint(name = "hint_drop_node", transform = "drop_node")
    runfiles_group_hint(name = "hint_protect_node", transform = "protect_node")
    runfiles_group_hint(name = "hint_drop_executable", transform = "drop_executable")
    unrelated_hint(name = "hint_unrelated")

    _hinted_binary("minimal_noop_hints", [":hint_noop"])
    _hinted_binary("minimal_rename_hints", [":hint_rename"])
    _hinted_binary("minimal_ab_hints", [":hint_prefix_a", ":hint_prefix_b"])
    _hinted_binary("minimal_ba_hints", [":hint_prefix_b", ":hint_prefix_a"])
    _hinted_binary("minimal_drop_node_hints", [":hint_drop_node"])
    _hinted_binary("minimal_protect_hints", [":hint_protect_node"])
    _hinted_binary("minimal_drop_exec_hints", [":hint_drop_executable"])
    _hinted_binary("minimal_unrelated_hints", [":hint_unrelated"])

    consume_groups(name = "consume_minimal", binary = ":minimal")
    consume_groups(name = "consume_noop", binary = ":minimal_noop_hints")
    consume_groups(name = "consume_rename", binary = ":minimal_rename_hints")
    consume_groups(name = "consume_ab", binary = ":minimal_ab_hints")
    consume_groups(name = "consume_ba", binary = ":minimal_ba_hints")
    consume_groups(name = "consume_drop_node", binary = ":minimal_drop_node_hints")
    consume_groups(name = "consume_protect", binary = ":minimal_protect_hints")
    consume_groups(name = "consume_drop_exec", binary = ":minimal_drop_exec_hints")
    consume_groups(name = "consume_unrelated", binary = ":minimal_unrelated_hints")

    _node = "aspect_rules_js#node"
    _support = "aspect_rules_js#runtime_support"
    _minimal = runfiles_groups.name_str(Label(":minimal"))
    _minimal_noop = runfiles_groups.name_str(Label(":minimal_noop_hints"))
    _minimal_unrelated = runfiles_groups.name_str(Label(":minimal_unrelated_hints"))
    _minimal_drop = runfiles_groups.name_str(Label(":minimal_drop_node_hints"))

    consumer_names_test(
        name = "consumer_no_hints_test",
        expect_contains = [_node, _support],
        expect_executable = _minimal,
        target_under_test = ":consume_minimal",
    )
    consumer_names_test(
        name = "consumer_noop_test",
        expect_contains = [_node, _support],
        expect_executable = _minimal_noop,
        target_under_test = ":consume_noop",
    )
    consumer_names_test(
        name = "consumer_rename_test",
        expect_contains = ["renamed_binary"],
        expect_executable = "renamed_binary",
        target_under_test = ":consume_rename",
    )
    consumer_names_test(
        name = "consumer_ab_test",
        expect_contains = ["b+a+" + _node],
        target_under_test = ":consume_ab",
    )
    consumer_names_test(
        name = "consumer_ba_test",
        expect_contains = ["a+b+" + _node],
        target_under_test = ":consume_ba",
    )
    consumer_names_test(
        name = "consumer_drop_node_test",
        expect_missing = [_node],
        expect_contains = [_support, _minimal_drop],
        target_under_test = ":consume_drop_node",
    )
    consumer_names_test(
        name = "consumer_unrelated_test",
        expect_contains = [_node, _support],
        expect_executable = _minimal_unrelated,
        target_under_test = ":consume_unrelated",
    )
    consumer_disabled_test(
        name = "consumer_disabled_fallback_test",
        expect_ungrouped = True,
        target_under_test = ":consume_minimal",
    )
    drop_executable_failure_test(
        name = "consumer_drop_executable_fails_test",
        target_under_test = ":consume_drop_exec",
    )
