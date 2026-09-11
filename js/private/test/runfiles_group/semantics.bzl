"""Analysis tests for RunfilesGroupInfo membership on rules_js fixtures.

Inspects groups already emitted by js_binary / js_library / npm producers.
Does not reimplement grouping to compute expected membership.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load("//js:providers.bzl", "JsInfo")
load("//js:runfiles_groups.bzl", "js_runfiles_groups")
load(
    "//js/private/test:runfiles_group_assertions.bzl",
    "DISABLED_CONFIG",
    "assert_allowed_overlaps",
    "assert_contains_files",
    "assert_empty_files",
    "assert_excludes_files",
    "assert_group_metadata",
    "assert_has_rgi",
    "assert_name_absent",
    "assert_no_rgi",
    "file_set",
    "files_list",
    "group_by_name",
    "related_admitted",
    "resolve_target",
    "runfiles_files",
    "semantics_test",
)

# Coverage execution is unchanged; grouping does not expose a coverage group.
_COVERAGE_GROUP = "aspect_rules_js#coverage"

def _assert_role(env, found, rf_files, original, expected_name, forbidden_names):
    related = related_admitted(rf_files, original)
    asserts.true(env, related, "no admitted file matching {}".format(original.basename))
    expected = found.get(expected_name)
    asserts.true(env, expected != None, "missing group {}".format(expected_name))
    assert_contains_files(env, expected, related)
    for name in forbidden_names:
        other = found.get(name)
        if other:
            assert_excludes_files(env, other, related)

def _p1_source_only_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    assert_no_rgi(env, target, "source-only library must omit RGI")
    rf = target[DefaultInfo].default_runfiles
    asserts.false(env, rf.files, "source-only library default_runfiles should be empty")
    return analysistest.end(env)

# js_library(srcs) has empty default_runfiles and no RunfilesGroupInfo.
p1_source_only_test = semantics_test(_p1_source_only_impl)

def _p1_package_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    assert_no_rgi(env, target, "npm_package must not invent runfiles RGI")
    return analysistest.end(env)

# npm_package is a build output, not a runfiles producer.
p1_package_test = semantics_test(_p1_package_impl)

def _p1_launcher_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    assert_no_rgi(env, target, "launcher-only derivative must not emit RGI")
    ftr = target[DefaultInfo].files_to_run
    asserts.true(env, ftr != None and ftr.executable != None, "create_launcher executable missing")
    asserts.true(env, target[DefaultInfo].default_runfiles != None, "create_launcher runfiles missing")
    return analysistest.end(env)

# create_launcher copies a js_binary executable without emitting RunfilesGroupInfo.
p1_launcher_only_test = semantics_test(_p1_launcher_impl)

def _p1_rebuilt_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    asserts.true(env, first != None)
    asserts.true(env, "rebuilt_rgi_sentinel.txt" in [f.basename for f in runfiles_groups.files(first).to_list()])
    asserts.equals(env, target.label, target[RunfilesGroupInfo].executable_group)
    return analysistest.end(env)

# A derivative that changes default runfiles after js_binary must rebuild RunfilesGroupInfo.
p1_rebuilt_semantics_test = semantics_test(_p1_rebuilt_impl)

def _p1_rebuilt_disabled_impl(ctx):
    env = analysistest.begin(ctx)
    assert_no_rgi(env, analysistest.target_under_test(env))
    return analysistest.end(env)

p1_rebuilt_disabled_test = analysistest.make(_p1_rebuilt_disabled_impl, config_settings = DISABLED_CONFIG)

# Launcher, entry point, and raw data sources are the protected application
# group. JsInfo sources (direct, transitive, types) are first_party. Binaries
# do not emit #npm or #coverage.
_P2_ATTRS = {
    "entry": attr.label(allow_single_file = True, mandatory = True),
    "raw_data": attr.label(allow_single_file = True, mandatory = True),
    "generated": attr.label(allow_single_file = True, mandatory = True),
    "immediate_src": attr.label(allow_single_file = True, mandatory = True),
    "immediate_types": attr.label(allow_single_file = True, mandatory = True),
    "transitive_src": attr.label(allow_single_file = True, mandatory = True),
    "opaque_src": attr.label(allow_single_file = True, mandatory = True),
}

def _p2_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    assert_has_rgi(env, target)
    resolved = resolve_target(ctx, target)
    found = group_by_name(resolved)
    rf_files = runfiles_files(target)
    app_name = runfiles_groups.name_str(target.label)
    app = found.get(app_name)
    asserts.true(env, app != None, "missing application group")
    assert_group_metadata(
        env,
        app,
        kind = "first_party",
        rank = js_runfiles_groups.RANK_EXECUTABLE,
        do_not_merge = True,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    asserts.equals(env, target.label, target[RunfilesGroupInfo].executable_group)
    asserts.equals(env, js_runfiles_groups.AFFINITY, app.merge_affinity)

    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    asserts.true(env, first != None)
    assert_group_metadata(
        env,
        first,
        kind = "first_party",
        rank = js_runfiles_groups.RANK_FIRST_PARTY_DEPS,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    third = found.get(js_runfiles_groups.THIRD_PARTY_GROUP)
    asserts.true(env, third != None)
    assert_group_metadata(
        env,
        third,
        kind = "third_party",
        rank = js_runfiles_groups.RANK_SHARED_DEPS,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    links = found.get(js_runfiles_groups.NPM_LINKS_GROUP)
    asserts.true(env, links != None)
    assert_group_metadata(
        env,
        links,
        kind = "",
        rank = js_runfiles_groups.RANK_NPM_LINKS,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    node = found.get(js_runfiles_groups.NODE_GROUP)
    asserts.true(env, node != None)
    assert_group_metadata(
        env,
        node,
        kind = "foundation",
        rank = js_runfiles_groups.RANK_FOUNDATION,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    support = found.get(js_runfiles_groups.RUNTIME_SUPPORT_GROUP)
    asserts.true(env, support != None)
    assert_group_metadata(
        env,
        support,
        kind = "foundation",
        rank = js_runfiles_groups.RANK_BOOTSTRAP,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )

    others_from_app = [
        js_runfiles_groups.FIRST_PARTY_GROUP,
        js_runfiles_groups.THIRD_PARTY_GROUP,
        js_runfiles_groups.NPM_LINKS_GROUP,
        js_runfiles_groups.NODE_GROUP,
        js_runfiles_groups.RUNTIME_SUPPORT_GROUP,
    ]
    others_from_first = [app_name, js_runfiles_groups.THIRD_PARTY_GROUP, js_runfiles_groups.NPM_LINKS_GROUP]
    exe = target[DefaultInfo].files_to_run.executable if target[DefaultInfo].files_to_run else None
    asserts.true(env, exe != None, "binary executable missing")
    assert_contains_files(env, found[app_name], [exe])
    for name in others_from_app:
        other = found.get(name)
        if other:
            assert_excludes_files(env, other, [exe])
    _assert_role(env, found, rf_files, ctx.file.entry, app_name, others_from_app)
    _assert_role(env, found, rf_files, ctx.file.raw_data, app_name, others_from_app)
    _assert_role(env, found, rf_files, ctx.file.generated, js_runfiles_groups.FIRST_PARTY_GROUP, others_from_first)
    _assert_role(env, found, rf_files, ctx.file.immediate_src, js_runfiles_groups.FIRST_PARTY_GROUP, others_from_first)
    _assert_role(env, found, rf_files, ctx.file.immediate_types, js_runfiles_groups.FIRST_PARTY_GROUP, others_from_first)
    _assert_role(env, found, rf_files, ctx.file.transitive_src, js_runfiles_groups.FIRST_PARTY_GROUP, others_from_first)
    _assert_role(env, found, rf_files, ctx.file.opaque_src, js_runfiles_groups.FIRST_PARTY_GROUP, others_from_first)

    assert_name_absent(env, found, js_runfiles_groups.NPM_GROUP)
    assert_name_absent(env, found, js_runfiles_groups.NPM_TOOLCHAIN_GROUP)
    assert_name_absent(env, found, _COVERAGE_GROUP)
    assert_allowed_overlaps(env, resolved, [])
    return analysistest.end(env)

p2_semantics_test = semantics_test(_p2_impl, attrs = _P2_ATTRS)

# first_party Files must not also appear in third_party.
def _swap_must_fail_helper(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    third = found.get(js_runfiles_groups.THIRD_PARTY_GROUP)
    if first and third:
        assert_excludes_files(env, third, runfiles_groups.files(first).to_list())
        assert_excludes_files(env, first, runfiles_groups.files(third).to_list())
    _assert_role(
        env,
        found,
        runfiles_files(target),
        ctx.file.immediate_src,
        js_runfiles_groups.FIRST_PARTY_GROUP,
        [js_runfiles_groups.THIRD_PARTY_GROUP],
    )
    return analysistest.end(env)

p2_swap_guard_test = semantics_test(_swap_must_fail_helper, attrs = {
    "immediate_src": attr.label(allow_single_file = True, mandatory = True),
})

_P3_ATTRS = {
    "owned_by_a": attr.label(allow_single_file = True, mandatory = True),
    "owned_by_b": attr.label(allow_single_file = True, mandatory = True),
    "owned_by_both": attr.label(allow_single_file = True, mandatory = True),
    "shared_dep": attr.label(allow_single_file = True, mandatory = True),
    "bin_a": attr.label(mandatory = True),
    "bin_b": attr.label(mandatory = True),
}

def _p3_limit_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = resolve_target(ctx, target)
    found = group_by_name(resolved)
    name_a = runfiles_groups.name_str(ctx.attr.bin_a.label)
    name_b = runfiles_groups.name_str(ctx.attr.bin_b.label)
    for name in [
        name_a,
        name_b,
        js_runfiles_groups.FIRST_PARTY_GROUP,
        js_runfiles_groups.THIRD_PARTY_GROUP,
        js_runfiles_groups.NPM_LINKS_GROUP,
        js_runfiles_groups.NODE_GROUP,
        js_runfiles_groups.RUNTIME_SUPPORT_GROUP,
    ]:
        asserts.true(env, name in found, "missing group {} before limit()".format(name))
    assert_name_absent(env, found, js_runfiles_groups.NPM_GROUP)
    assert_name_absent(env, found, js_runfiles_groups.NPM_TOOLCHAIN_GROUP)
    assert_name_absent(env, found, _COVERAGE_GROUP)
    asserts.equals(env, 7, len(resolved.groups))

    rf_files = runfiles_files(target)
    _assert_role(env, found, rf_files, ctx.file.owned_by_a, name_a, [name_b, js_runfiles_groups.FIRST_PARTY_GROUP])
    _assert_role(env, found, rf_files, ctx.file.owned_by_b, name_b, [name_a, js_runfiles_groups.FIRST_PARTY_GROUP])
    _assert_role(env, found, rf_files, ctx.file.shared_dep, js_runfiles_groups.FIRST_PARTY_GROUP, [name_a, name_b])
    both = ctx.file.owned_by_both
    asserts.true(env, both in rf_files, "shared application File not admitted")
    assert_contains_files(env, found[name_a], [both])
    assert_contains_files(env, found[name_b], [both])
    assert_allowed_overlaps(env, resolved, [sorted([name_a, name_b])])

    limited = runfiles_groups.limit(ctx, resolved, max_groups = 1)
    asserts.equals(env, 7, limited.group_count)
    limited_found = group_by_name(limited)
    asserts.true(env, limited_found[name_a].do_not_merge)
    asserts.true(env, limited_found[name_b].do_not_merge)
    for name in [
        js_runfiles_groups.FIRST_PARTY_GROUP,
        js_runfiles_groups.THIRD_PARTY_GROUP,
        js_runfiles_groups.NPM_LINKS_GROUP,
        js_runfiles_groups.NODE_GROUP,
        js_runfiles_groups.RUNTIME_SUPPORT_GROUP,
    ]:
        asserts.equals(env, False, limited_found[name].do_not_merge)
    _assert_role(env, limited_found, rf_files, ctx.file.owned_by_a, name_a, [name_b, js_runfiles_groups.FIRST_PARTY_GROUP])
    _assert_role(env, limited_found, rf_files, ctx.file.owned_by_b, name_b, [name_a, js_runfiles_groups.FIRST_PARTY_GROUP])
    return analysistest.end(env)

# Shared mergeable groups fold by name; protected application groups stay distinct.
# limit(max_groups=1) does not drop those protected groups.
p3_limit_semantics_test = semantics_test(_p3_limit_impl, attrs = _P3_ATTRS)

def _p5_loss_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    asserts.true(env, first != None)
    names = [f.basename for f in runfiles_groups.files(first).to_list()]
    asserts.true(
        env,
        "p5_pkg" in names or "package.json" in names or "index.js" in names or "local_index.js" in names,
        "expected wrapped package tree in first_party, got {}".format(names),
    )
    return analysistest.end(env)

# js_library(srcs = [npm_package]) exposes a generated tree, so the binary treats it as first_party.
p5_loss_semantics_test = semantics_test(_p5_loss_impl)

def _p5_link_coarse_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    asserts.true(env, js_runfiles_groups.NPM_GROUP in found)
    assert_group_metadata(
        env,
        found[js_runfiles_groups.NPM_GROUP],
        kind = "",
        rank = js_runfiles_groups.RANK_NPM_LINKS,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    asserts.true(env, js_runfiles_groups.NPM_LINKS_GROUP in found)
    return analysistest.end(env)

# npm_link_package emits coarse #npm plus #npm_links. js_binary later drops #npm.
p5_link_coarse_semantics_test = semantics_test(_p5_link_coarse_impl)

def _p5_custom_npm_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    third = found.get(js_runfiles_groups.THIRD_PARTY_GROUP)
    asserts.true(env, third != None, "missing third_party; groups={}".format(sorted(found.keys())))
    pkg = ctx.file.custom_pkg
    _assert_role(
        env,
        found,
        runfiles_files(target),
        pkg,
        js_runfiles_groups.THIRD_PARTY_GROUP,
        [js_runfiles_groups.FIRST_PARTY_GROUP, js_runfiles_groups.NPM_LINKS_GROUP],
    )
    return analysistest.end(env)

# NpmPackageInfo.src on data is third_party, even without going through npm_link_package.
p5_custom_npm_semantics_test = semantics_test(_p5_custom_npm_impl, attrs = {
    "custom_pkg": attr.label(allow_single_file = True, mandatory = True),
})

def _p5_external_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    rf_files = runfiles_files(target)
    _assert_role(
        env,
        found,
        rf_files,
        ctx.file.root_a,
        js_runfiles_groups.FIRST_PARTY_GROUP,
        [js_runfiles_groups.THIRD_PARTY_GROUP],
    )
    _assert_role(
        env,
        found,
        rf_files,
        ctx.file.root_b,
        js_runfiles_groups.FIRST_PARTY_GROUP,
        [js_runfiles_groups.THIRD_PARTY_GROUP],
    )
    return analysistest.end(env)

# Source-backed JS from another module is first_party (representation at admission, not repo identity).
p5_external_semantics_test = semantics_test(_p5_external_impl, attrs = {
    "root_a": attr.label(allow_single_file = True, mandatory = True),
    "root_b": attr.label(allow_single_file = True, mandatory = True),
})

def _p5_link_as_src_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    asserts.true(env, js_runfiles_groups.THIRD_PARTY_GROUP in found or js_runfiles_groups.NPM_LINKS_GROUP in found)
    admitted = [f for f in runfiles_files(target) if "/.aspect_rules_js/" in f.path]
    asserts.true(env, admitted, "expected admitted npm store/link payload")
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    if first:
        assert_excludes_files(env, first, admitted)
    owned = False
    for name in [js_runfiles_groups.THIRD_PARTY_GROUP, js_runfiles_groups.NPM_LINKS_GROUP]:
        group = found.get(name)
        if not group:
            continue
        have = file_set(files_list(group))
        for f in admitted:
            if f in have:
                owned = True
                break
    asserts.true(env, owned, "admitted npm payload missing from third_party/npm_links")
    return analysistest.end(env)

# js_library(srcs = [npm_link_package]) still classifies the package tree as npm, not first_party.
p5_link_as_src_semantics_test = semantics_test(_p5_link_as_src_impl)

def _p6_marker_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    marker = js_runfiles_groups.NODE_EXTERNAL_PREFIX + runfiles_groups.name_str(target.label)
    asserts.true(env, marker in found, "missing {}".format(marker))
    assert_group_metadata(
        env,
        found[marker],
        kind = "foundation",
        rank = js_runfiles_groups.RANK_FOUNDATION,
        do_not_merge = True,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    assert_empty_files(env, found[marker])
    assert_name_absent(env, found, js_runfiles_groups.NODE_GROUP)
    return analysistest.end(env)

# Path-only Node toolchains emit an empty #node_external:<label> marker, not #node.
p6_marker_semantics_test = semantics_test(_p6_marker_impl)

def _p6_passthrough_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    assert_has_rgi(env, target)
    asserts.equals(env, None, target[RunfilesGroupInfo].executable_group)
    return analysistest.end(env)

# Relaying RunfilesGroupInfo without an executable_group is allowed for non-binaries.
p6_passthrough_semantics_test = semantics_test(_p6_passthrough_impl)

def _p6_nested_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    inner = runfiles_groups.name_str(ctx.attr.inner.label)
    asserts.true(env, inner in found, "nested inner application missing")
    assert_group_metadata(
        env,
        found[inner],
        kind = "first_party",
        rank = js_runfiles_groups.RANK_EXECUTABLE,
        do_not_merge = True,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    asserts.equals(env, target.label, target[RunfilesGroupInfo].executable_group)
    asserts.true(env, found[runfiles_groups.name_str(target.label)].do_not_merge)
    return analysistest.end(env)

# A js_binary in data keeps its own protected application group on the outer binary.
p6_nested_semantics_test = semantics_test(_p6_nested_impl, attrs = {
    "inner": attr.label(mandatory = True),
})

def _p6_drop_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    inner = runfiles_groups.name_str(ctx.attr.inner.label)
    assert_name_absent(env, found, inner)
    return analysistest.end(env)

# A data dep that drops RunfilesGroupInfo is not recovered as a nested application group.
p6_drop_semantics_test = semantics_test(_p6_drop_impl, attrs = {
    "inner": attr.label(mandatory = True),
})

def _p6_foreign_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = resolve_target(ctx, target)
    found = group_by_name(resolved)
    protected = found.get("foreign#protected")
    asserts.true(env, protected != None, "foreign protected group missing")
    assert_group_metadata(
        env,
        protected,
        kind = "docs",
        rank = js_runfiles_groups.RANK_FOUNDATION,
        do_not_merge = True,
        merge_affinity = "foreign",
    )
    mixed = found.get("foreign#mixed")
    asserts.true(env, mixed != None, "foreign mixed group missing")
    assert_group_metadata(
        env,
        mixed,
        kind = "docs",
        rank = 50,
        do_not_merge = False,
        merge_affinity = "foreign",
        weight = 3,
    )
    has_symlink = False
    has_root = False
    for g in resolved.groups:
        rf = runfiles_groups.runfiles(ctx, g)
        if rf.symlinks and rf.symlinks.to_list():
            has_symlink = True
        if rf.root_symlinks and rf.root_symlinks.to_list():
            has_root = True
    asserts.true(env, has_symlink, "expected preserved foreign symlink")
    asserts.true(env, has_root, "expected preserved foreign root symlink")
    return analysistest.end(env)

# Non-rules_js RunfilesGroupInfo, symlinks, and root_symlinks are preserved.
p6_foreign_semantics_test = semantics_test(_p6_foreign_impl)

def _p6_copied_node_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    node = found.get(js_runfiles_groups.NODE_GROUP)
    asserts.true(env, node != None)
    names = [f.basename for f in runfiles_groups.files(node).to_list()]
    asserts.true(env, "copied_node_tc_node" in names, "copied Node File missing from #node: {}".format(names))
    return analysistest.end(env)

# A copied Node executable File is classified as #node.
p6_copied_node_semantics_test = semantics_test(_p6_copied_node_impl)

_P4_JSINFO_ATTRS = {
    "jsinfo": attr.label(mandatory = True, providers = [JsInfo]),
}

def _jsinfo_named(jsinfo, suffix):
    for f in jsinfo.transitive_sources.to_list() + jsinfo.transitive_types.to_list() + jsinfo.npm_sources.to_list():
        if f.basename.endswith(suffix):
            return f
    fail("no JsInfo file ending with {}".format(suffix))

def _p4_none_impl(ctx):
    env = analysistest.begin(ctx)
    found = group_by_name(resolve_target(ctx, analysistest.target_under_test(env)))
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    third = found.get(js_runfiles_groups.THIRD_PARTY_GROUP)
    first_names = [f.basename for f in runfiles_groups.files(first).to_list()] if first else []
    third_names = [f.basename for f in runfiles_groups.files(third).to_list()] if third else []
    for name in ["p4_jsinfo_s_direct.js", "p4_jsinfo_s_transitive.js", "p4_jsinfo_t_direct.d.ts", "p4_jsinfo_t_transitive.d.ts"]:
        asserts.false(env, name in first_names, "excluded source/type {} leaked into first_party".format(name))
    asserts.false(env, "p4_jsinfo_npm.js" in third_names, "excluded npm sentinel leaked into third_party")
    return analysistest.end(env)

# include_* flags that are false keep the corresponding JsInfo files out of runfiles.
p4_none_semantics_test = semantics_test(_p4_none_impl)

def _p4_direct_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    jsinfo = ctx.attr.jsinfo[JsInfo]
    rf_files = runfiles_files(target)
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_s_direct.js"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_t_direct.d.ts"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    assert_excludes_files(env, first, [_jsinfo_named(jsinfo, "_s_transitive.js")])
    return analysistest.end(env)

# include_sources / include_types admit direct JsInfo files as first_party.
p4_direct_semantics_test = semantics_test(_p4_direct_impl, attrs = _P4_JSINFO_ATTRS)

def _p4_trans_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    jsinfo = ctx.attr.jsinfo[JsInfo]
    rf_files = runfiles_files(target)
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_s_transitive.js"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_t_transitive.d.ts"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    return analysistest.end(env)

# include_transitive_sources / include_transitive_types admit transitive JsInfo files.
p4_trans_semantics_test = semantics_test(_p4_trans_impl, attrs = _P4_JSINFO_ATTRS)

def _p4_both_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    jsinfo = ctx.attr.jsinfo[JsInfo]
    rf_files = runfiles_files(target)
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_s_direct.js"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_s_transitive.js"), js_runfiles_groups.FIRST_PARTY_GROUP, [js_runfiles_groups.THIRD_PARTY_GROUP])
    _assert_role(env, found, rf_files, _jsinfo_named(jsinfo, "_npm.js"), js_runfiles_groups.THIRD_PARTY_GROUP, [js_runfiles_groups.FIRST_PARTY_GROUP])
    return analysistest.end(env)

# Direct sources are first_party; npm_sources from JsInfo are third_party.
p4_both_semantics_test = semantics_test(_p4_both_impl, attrs = _P4_JSINFO_ATTRS)

def _p4_include_npm_impl(ctx):
    env = analysistest.begin(ctx)
    found = group_by_name(resolve_target(ctx, analysistest.target_under_test(env)))
    toolchain = found.get(js_runfiles_groups.NPM_TOOLCHAIN_GROUP)
    asserts.true(env, toolchain != None, "include_npm must emit #npm_toolchain")
    assert_group_metadata(
        env,
        toolchain,
        kind = "foundation",
        rank = js_runfiles_groups.RANK_BOOTSTRAP,
        do_not_merge = False,
        merge_affinity = js_runfiles_groups.AFFINITY,
    )
    assert_name_absent(env, found, _COVERAGE_GROUP)
    return analysistest.end(env)

# include_npm puts the npm CLI wrapper files in #npm_toolchain.
p4_include_npm_semantics_test = semantics_test(_p4_include_npm_impl)

def _p4_coverage_impl(ctx):
    env = analysistest.begin(ctx)
    found = group_by_name(resolve_target(ctx, analysistest.target_under_test(env)))
    assert_name_absent(env, found, _COVERAGE_GROUP)
    return analysistest.end(env)

# Coverage execution files are not a named grouping role.
p4_coverage_semantics_test = analysistest.make(
    _p4_coverage_impl,
    config_settings = {
        str(Label("@rules_runfiles_group//runfiles_group:enabled")): True,
        "//command_line_option:collect_code_coverage": True,
    },
)

def _p4_copy_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    rf_files = runfiles_files(target)
    app_name = runfiles_groups.name_str(target.label)
    keep = related_admitted(rf_files, ctx.file.keep)
    skip = related_admitted(rf_files, ctx.file.skip)
    asserts.true(env, len(keep) > 1, "expected copied keep file plus original")
    asserts.equals(env, 1, len(skip), "no-copy exception must not add a copy")
    _assert_role(env, found, rf_files, ctx.file.keep, app_name, [js_runfiles_groups.FIRST_PARTY_GROUP])
    _assert_role(env, found, rf_files, ctx.file.skip, app_name, [js_runfiles_groups.FIRST_PARTY_GROUP])
    return analysistest.end(env)

# copy_data_to_bin copies ordinary data into the application group; no_copy_to_bin skips that copy.
p4_copy_semantics_test = semantics_test(_p4_copy_impl, attrs = {
    "keep": attr.label(allow_single_file = True, mandatory = True),
    "skip": attr.label(allow_single_file = True, mandatory = True),
})

def _p4_grouped_copy_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = resolve_target(ctx, target)
    asserts.true(env, resolved != None, "library with grouped data must emit RGI")
    related = related_admitted(runfiles_files(target), ctx.file.original)
    asserts.true(env, len(related) > 1, "expected original plus copy on the library")
    grouped = {}
    for g in resolved.groups:
        for f in runfiles_groups.files(g).to_list():
            grouped[f] = True
    for f in related:
        asserts.true(env, f in grouped, "admitted {} missing from library RGI".format(f.path))
    return analysistest.end(env)

# Copying a source that is already in a grouped dep still admits the copy.
p4_grouped_copy_semantics_test = semantics_test(_p4_grouped_copy_impl, attrs = {
    "original": attr.label(allow_single_file = True, mandatory = True),
})

def _p4_generated_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    _assert_role(
        env,
        found,
        runfiles_files(target),
        ctx.file.generated,
        js_runfiles_groups.FIRST_PARTY_GROUP,
        [runfiles_groups.name_str(target.label)],
    )
    return analysistest.end(env)

# Generated ordinary data (write_file / genrule) is first_party, not the application group.
p4_generated_semantics_test = semantics_test(_p4_generated_impl, attrs = {
    "generated": attr.label(allow_single_file = True, mandatory = True),
})

def _p4_dir_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    app = found.get(runfiles_groups.name_str(target.label))
    asserts.true(env, app != None)
    trees = [f for f in runfiles_groups.files(app).to_list() if f.is_directory]
    asserts.true(env, trees, "expected TreeArtifact entry point in the application group")
    return analysistest.end(env)

# A TreeArtifact entry point stays in the protected application group.
p4_dir_semantics_test = semantics_test(_p4_dir_impl)

def _p4_proto_impl(ctx):
    env = analysistest.begin(ctx)
    found = group_by_name(resolve_target(ctx, analysistest.target_under_test(env)))
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    asserts.true(env, first != None)
    names = [f.basename for f in runfiles_groups.files(first).to_list()]
    has_proto_js = False
    for n in names:
        if n.endswith(".js") or "_pb" in n:
            has_proto_js = True
            break
    asserts.true(env, has_proto_js, "expected generated proto JS in first_party, got {}".format(names))
    return analysistest.end(env)

# js_proto_aspect is JsInfo-only; generated JS admitted by js_binary is first_party.
p4_proto_semantics_test = semantics_test(_p4_proto_impl)

def _p4_no_copy_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    rf_files = runfiles_files(target)
    related = related_admitted(rf_files, ctx.file.raw_data)
    asserts.equals(env, 1, len(related), "copying disabled must keep the original File only")
    _assert_role(env, found, rf_files, ctx.file.raw_data, runfiles_groups.name_str(target.label), [js_runfiles_groups.FIRST_PARTY_GROUP])
    return analysistest.end(env)

# copy_data_to_bin = False keeps the original source File in the application group.
p4_no_copy_semantics_test = semantics_test(_p4_no_copy_impl, attrs = {
    "raw_data": attr.label(allow_single_file = True, mandatory = True),
})

def _p6_library_relay_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    resolved = resolve_target(ctx, target)
    asserts.true(env, resolved != None, "library with extra data runfiles must emit RGI")
    if ctx.attr.expect_symlinks:
        has_symlink = False
        has_root = False
        for g in resolved.groups:
            rf = runfiles_groups.runfiles(ctx, g)
            if rf.symlinks and rf.symlinks.to_list():
                has_symlink = True
            if rf.root_symlinks and rf.root_symlinks.to_list():
                has_root = True
        asserts.true(env, has_symlink, "library dropped inherited symlinks")
        asserts.true(env, has_root, "library dropped inherited root_symlinks")
    extra = ctx.attr.extra_basename
    if extra:
        names = []
        for g in resolved.groups:
            names.extend([f.basename for f in runfiles_groups.files(g).to_list()])
        asserts.true(env, extra in names, "library dropped extra runfiles file {}".format(extra))
    return analysistest.end(env)

# js_library must relay complete admitted runfiles, including extra filegroup
# data and symlink/root_symlink components.
p6_library_relay_semantics_test = semantics_test(_p6_library_relay_impl, attrs = {
    "expect_symlinks": attr.bool(),
    "extra_basename": attr.string(),
})

def _p6_exec_vs_raw_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    found = group_by_name(resolve_target(ctx, target))
    app_name = runfiles_groups.name_str(target.label)
    _assert_role(
        env,
        found,
        runfiles_files(target),
        ctx.file.raw_data,
        app_name,
        [js_runfiles_groups.FIRST_PARTY_GROUP],
    )
    exec_name = runfiles_groups.name_str(ctx.attr.executable_dep.label)
    asserts.true(env, exec_name in found, "single-output executable should keep a Label group")
    exec_files = files_list(found[exec_name])
    asserts.true(env, exec_files, "executable Label group is empty")
    first = found.get(js_runfiles_groups.FIRST_PARTY_GROUP)
    if first:
        assert_excludes_files(env, first, exec_files)
    return analysistest.end(env)

# A generated single-output executable is not ordinary data; a raw File still is.
p6_exec_vs_raw_semantics_test = semantics_test(_p6_exec_vs_raw_impl, attrs = {
    "raw_data": attr.label(allow_single_file = True, mandatory = True),
    "executable_dep": attr.label(mandatory = True),
})
