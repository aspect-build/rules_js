"""Custom analysis tests for companion channels, metadata, disablement, and contents."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load("//js/private:js_info.bzl", "JsInfo")
load("//js/private:js_runfiles_groups.bzl", "JsRunfilesGroupsInfo", "js_runfiles_groups")

_ENABLED = {
    str(Label("@rules_runfiles_group//runfiles_group:enabled")): True,
}
_DISABLED = {
    str(Label("@rules_runfiles_group//runfiles_group:enabled")): False,
}

def _entry_files(entries):
    return depset(transitive = [runfiles_groups.files(e) for e in entries.to_list()])

def _basenames(files):
    return sorted([f.basename for f in files.to_list()])

def _companion_equality_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.true(env, JsInfo in target, "expected JsInfo")
    asserts.true(env, JsRunfilesGroupsInfo in target, "expected JsRunfilesGroupsInfo")
    jsinfo = target[JsInfo]
    companion = target[JsRunfilesGroupsInfo]
    asserts.equals(env, _basenames(jsinfo.sources), _basenames(_entry_files(companion.sources)))
    asserts.equals(env, _basenames(jsinfo.types), _basenames(_entry_files(companion.types)))
    asserts.equals(env, _basenames(jsinfo.transitive_sources), _basenames(_entry_files(companion.transitive_sources)))
    asserts.equals(env, _basenames(jsinfo.transitive_types), _basenames(_entry_files(companion.transitive_types)))
    asserts.equals(env, _basenames(jsinfo.npm_sources), _basenames(_entry_files(companion.npm_sources)))
    asserts.equals(env, _basenames(target[DefaultInfo].files), _basenames(_entry_files(companion.default_files)))
    return analysistest.end(env)

companion_equality_test = analysistest.make(
    _companion_equality_impl,
    config_settings = _ENABLED,
)

def _no_grouping_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.false(env, RunfilesGroupInfo in target, "disabled: no RunfilesGroupInfo")
    asserts.false(env, JsRunfilesGroupsInfo in target, "disabled: no JsRunfilesGroupsInfo")
    return analysistest.end(env)

no_grouping_test = analysistest.make(
    _no_grouping_impl,
    config_settings = _DISABLED,
)

def _native_metadata_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.true(env, RunfilesGroupInfo in target)
    resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
    asserts.true(env, resolved != None)
    found = {}
    for g in resolved.groups:
        name = runfiles_groups.name_str(g.name)
        found[name] = g
        if name.startswith("aspect_rules_js#") or g.name == target.label:
            asserts.equals(env, False, g.do_not_merge)
            asserts.equals(env, None, g.weight)
            asserts.equals(env, js_runfiles_groups.MERGE_AFFINITY, g.merge_affinity)
    asserts.true(env, js_runfiles_groups.NODE_GROUP in found)
    asserts.equals(env, "foundation", found[js_runfiles_groups.NODE_GROUP].kind)
    asserts.equals(env, js_runfiles_groups.RANK_FOUNDATION, found[js_runfiles_groups.NODE_GROUP].rank)
    asserts.true(env, js_runfiles_groups.RUNTIME_SUPPORT_GROUP in found)
    asserts.equals(env, "foundation", found[js_runfiles_groups.RUNTIME_SUPPORT_GROUP].kind)
    bin_name = runfiles_groups.name_str(target.label)
    asserts.true(env, bin_name in found)
    asserts.equals(env, "first_party", found[bin_name].kind)
    asserts.equals(env, js_runfiles_groups.RANK_EXECUTABLE, found[bin_name].rank)
    return analysistest.end(env)

native_metadata_test = analysistest.make(
    _native_metadata_impl,
    config_settings = _ENABLED,
)

def _channel_contents_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
    asserts.true(env, resolved != None)
    names = {}
    for g in resolved.groups:
        for f in runfiles_groups.files(g).to_list():
            names[f.basename] = True
    for want in ctx.attr.expect_present:
        asserts.true(env, want in names, "expected %s in grouped files, got %s" % (want, names.keys()))
    for absent in ctx.attr.expect_absent:
        asserts.false(env, absent in names, "did not expect %s in grouped files" % absent)
    return analysistest.end(env)

channel_contents_test = analysistest.make(
    _channel_contents_impl,
    attrs = {
        "expect_present": attr.string_list(),
        "expect_absent": attr.string_list(),
    },
    config_settings = _ENABLED,
)

def _has_rgi_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    asserts.true(env, RunfilesGroupInfo in target, "expected RunfilesGroupInfo")
    rgi = target[RunfilesGroupInfo]
    asserts.equals(env, target.label, rgi.executable_group)
    if ctx.attr.expect_no_node:
        resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
        names = [runfiles_groups.name_str(g.name) for g in resolved.groups]
        asserts.false(env, js_runfiles_groups.NODE_GROUP in names, "node-path toolchain must omit node group")
        asserts.true(env, js_runfiles_groups.RUNTIME_SUPPORT_GROUP in names)
    if ctx.attr.expect_coverage:
        resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
        support = [g for g in resolved.groups if runfiles_groups.name_str(g.name) == js_runfiles_groups.RUNTIME_SUPPORT_GROUP]
        asserts.true(env, len(support) == 1)
        support_names = [f.basename for f in runfiles_groups.files(support[0]).to_list()]
        asserts.true(env, "coverage.cjs" in support_names, "coverage bootstrap belongs in runtime_support")
    if ctx.attr.expect_windows_exe:
        resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
        bin_name = runfiles_groups.name_str(target.label)
        grouped = [g for g in resolved.groups if runfiles_groups.name_str(g.name) == bin_name]
        asserts.true(env, len(grouped) == 1)
        basenames = [f.basename for f in runfiles_groups.files(grouped[0]).to_list()]
        asserts.true(env, any([n.endswith(".exe") or n.endswith(".bat") or n == target.label.name for n in basenames]), basenames)
    if ctx.attr.expect_node_repo:
        resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
        node_g = [g for g in resolved.groups if runfiles_groups.name_str(g.name) == js_runfiles_groups.NODE_GROUP]
        asserts.true(env, len(node_g) == 1)
        paths = [f.path for f in runfiles_groups.files(node_g[0]).to_list()]
        asserts.true(
            env,
            any([ctx.attr.expect_node_repo in p for p in paths]),
            "expected node file from %s, got %s" % (ctx.attr.expect_node_repo, paths),
        )
    return analysistest.end(env)

has_rgi_test = analysistest.make(
    _has_rgi_impl,
    attrs = {
        "expect_no_node": attr.bool(default = False),
        "expect_coverage": attr.bool(default = False),
        "expect_windows_exe": attr.bool(default = False),
        "expect_node_repo": attr.string(default = ""),
    },
    config_settings = _ENABLED,
)

has_rgi_coverage_test = analysistest.make(
    _has_rgi_impl,
    attrs = {
        "expect_no_node": attr.bool(default = False),
        "expect_coverage": attr.bool(default = False),
        "expect_windows_exe": attr.bool(default = False),
        "expect_node_repo": attr.string(default = ""),
    },
    config_settings = _ENABLED | {
        "//command_line_option:collect_code_coverage": True,
        "//command_line_option:instrumentation_filter": "//js/private/test/runfiles_group[:/]",
    },
)

has_rgi_no_runfiles_test = analysistest.make(
    _has_rgi_impl,
    attrs = {
        "expect_no_node": attr.bool(default = False),
        "expect_coverage": attr.bool(default = False),
        "expect_windows_exe": attr.bool(default = False),
        "expect_node_repo": attr.string(default = ""),
    },
    config_settings = _ENABLED | {
        "//command_line_option:enable_runfiles": "0",
    },
)

has_rgi_windows_test = analysistest.make(
    _has_rgi_impl,
    attrs = {
        "expect_no_node": attr.bool(default = False),
        "expect_coverage": attr.bool(default = False),
        "expect_windows_exe": attr.bool(default = False),
        "expect_node_repo": attr.string(default = ""),
    },
    config_settings = _ENABLED | {
        "//command_line_option:platforms": str(Label("//js/private/test/runfiles_group:windows_x86_64")),
    },
)

has_rgi_linux_arm64_test = analysistest.make(
    _has_rgi_impl,
    attrs = {
        "expect_no_node": attr.bool(default = False),
        "expect_coverage": attr.bool(default = False),
        "expect_windows_exe": attr.bool(default = False),
        "expect_node_repo": attr.string(default = ""),
    },
    config_settings = _ENABLED | {
        "//command_line_option:platforms": str(Label("//js/private/test/runfiles_group:linux_arm64")),
    },
)

def _foreign_metadata_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = runfiles_groups.resolve(ctx, target, aspect_hints = [])
    found = [g for g in resolved.groups if runfiles_groups.name_str(g.name) == ctx.attr.expect_name]
    asserts.true(env, len(found) >= 1, "missing group %s" % ctx.attr.expect_name)
    g = found[0]
    if ctx.attr.expect_kind:
        asserts.equals(env, ctx.attr.expect_kind, g.kind)
    if ctx.attr.expect_do_not_merge:
        asserts.equals(env, True, g.do_not_merge)
    if ctx.attr.expect_weight >= 0:
        asserts.equals(env, ctx.attr.expect_weight, g.weight)
    return analysistest.end(env)

foreign_metadata_test = analysistest.make(
    _foreign_metadata_impl,
    attrs = {
        "expect_name": attr.string(mandatory = True),
        "expect_kind": attr.string(default = ""),
        "expect_do_not_merge": attr.bool(default = False),
        "expect_weight": attr.int(default = -1),
    },
    config_settings = _ENABLED,
)

def custom_analysis_tests():
    """Declares metadata/projection analysis tests."""
    companion_equality_test(
        name = "library_companion_equality_test",
        target_under_test = ":leaf",
    )
    no_grouping_test(
        name = "library_disabled_test",
        target_under_test = ":leaf",
    )
    no_grouping_test(
        name = "npm_link_disabled_test",
        target_under_test = "//:node_modules/chalk",
    )
    no_grouping_test(
        name = "proto_disabled_test",
        target_under_test = ":g15_proto",
    )
    native_metadata_test(
        name = "minimal_metadata_test",
        target_under_test = ":minimal",
    )
    channel_contents_test(
        name = "isolated_default_contents_test",
        expect_absent = [
            "isolated_jsinfo_t_direct.d.ts",
            "isolated_jsinfo_t_transitive.d.ts",
        ],
        expect_present = [
            "isolated_jsinfo_s_direct.js",
            "isolated_jsinfo_s_transitive.js",
            "isolated_jsinfo_npm.js",
        ],
        target_under_test = ":isolated_default",
    )
    channel_contents_test(
        name = "isolated_none_contents_test",
        expect_absent = [
            "isolated_jsinfo_s_direct.js",
            "isolated_jsinfo_s_transitive.js",
            "isolated_jsinfo_t_direct.d.ts",
            "isolated_jsinfo_t_transitive.d.ts",
            "isolated_jsinfo_npm.js",
        ],
        target_under_test = ":isolated_none",
    )
    channel_contents_test(
        name = "isolated_types_contents_test",
        expect_absent = [
            "isolated_jsinfo_s_direct.js",
            "isolated_jsinfo_s_transitive.js",
            "isolated_jsinfo_npm.js",
        ],
        expect_present = [
            "isolated_jsinfo_t_direct.d.ts",
            "isolated_jsinfo_t_transitive.d.ts",
        ],
        target_under_test = ":isolated_types",
    )
    channel_contents_test(
        name = "typed_lib_contents_test",
        expect_present = [
            "lib.d.ts",
            "lib.d.mts",
            "lib.d.cts",
        ],
        target_under_test = ":typed_bin",
    )
    channel_contents_test(
        name = "json_tree_contents_test",
        expect_present = ["pkg.json"],
        target_under_test = ":json_tree_bin",
    )
    has_rgi_test(
        name = "custom_lib_rgi_test",
        target_under_test = ":custom_grouped",
    )
    has_rgi_test(
        name = "node_path_no_node_test",
        expect_no_node = True,
        target_under_test = ":node_path_bin",
    )
    has_rgi_test(
        name = "toolchain_override_test",
        expect_node_repo = "nodejs_linux_amd64",
        target_under_test = ":toolchain_override_bin",
    )
    has_rgi_coverage_test(
        name = "coverage_binary_test",
        expect_coverage = True,
        target_under_test = ":minimal",
    )
    has_rgi_coverage_test(
        name = "coverage_test_bin_test",
        expect_coverage = True,
        target_under_test = ":minimal_test_bin",
    )
    has_rgi_coverage_test(
        name = "coverage_custom_test",
        expect_coverage = True,
        target_under_test = ":custom_grouped_test",
    )
    has_rgi_no_runfiles_test(
        name = "noenable_runfiles_test",
        target_under_test = ":minimal",
    )
    has_rgi_windows_test(
        name = "windows_platform_test",
        expect_windows_exe = True,
        target_under_test = ":minimal",
    )
    has_rgi_linux_arm64_test(
        name = "linux_arm64_platform_test",
        expect_node_repo = "linux_arm64",
        target_under_test = ":minimal",
    )
    foreign_metadata_test(
        name = "protected_metadata_test",
        expect_do_not_merge = True,
        expect_kind = "docs",
        expect_name = "foreign#protected",
        target_under_test = ":protected_bin",
    )
    foreign_metadata_test(
        name = "dup_fold_metadata_test",
        expect_do_not_merge = True,
        expect_kind = "docs",
        expect_name = "foreign#dup",
        expect_weight = 8,
        target_under_test = ":dup_names_bin",
    )
