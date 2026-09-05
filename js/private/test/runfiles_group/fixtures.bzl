"""Test-only producers for runfiles-group fixtures."""

load("@bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load("//js:libs.bzl", "js_binary_lib")
load("//js/private:js_info.bzl", "js_info")
load("//js/private:js_runfiles_groups.bzl", "js_runfiles_groups")

def _empty_jsinfo_impl(ctx):
    s_direct = ctx.actions.declare_file("{}_s_direct.js".format(ctx.label.name))
    s_trans = ctx.actions.declare_file("{}_s_transitive.js".format(ctx.label.name))
    t_direct = ctx.actions.declare_file("{}_t_direct.d.ts".format(ctx.label.name))
    t_trans = ctx.actions.declare_file("{}_t_transitive.d.ts".format(ctx.label.name))
    npm_file = ctx.actions.declare_file("{}_npm.js".format(ctx.label.name))
    for f in [s_direct, s_trans, t_direct, t_trans, npm_file]:
        ctx.actions.write(f, "")

    sources = depset([s_direct])
    types = depset([t_direct])
    transitive_sources = depset([s_direct, s_trans])
    transitive_types = depset([t_direct, t_trans])
    npm_sources = depset([npm_file])

    providers = [
        DefaultInfo(files = depset(), runfiles = ctx.runfiles()),
        js_info(
            target = ctx.label,
            sources = sources,
            types = types,
            transitive_sources = transitive_sources,
            transitive_types = transitive_types,
            npm_sources = npm_sources,
        ),
    ]
    if js_runfiles_groups.is_enabled(ctx) and ctx.attr.emit_companion:
        e_src = js_runfiles_groups.native_entry(ctx.label, sources, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
        e_src_t = js_runfiles_groups.native_entry(ctx.label, transitive_sources, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
        e_typ = js_runfiles_groups.native_entry(ctx.label, types, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
        e_typ_t = js_runfiles_groups.native_entry(ctx.label, transitive_types, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
        e_npm = js_runfiles_groups.native_entry(ctx.label, npm_sources, "first_party", js_runfiles_groups.RANK_EXECUTABLE)
        providers.append(js_runfiles_groups.JsRunfilesGroupsInfo(
            sources = js_runfiles_groups.entries(direct = [e_src]),
            types = js_runfiles_groups.entries(direct = [e_typ]),
            transitive_sources = js_runfiles_groups.entries(direct = [e_src_t]),
            transitive_types = js_runfiles_groups.entries(direct = [e_typ_t]),
            npm_sources = js_runfiles_groups.entries(direct = [e_npm]),
        ))
    return providers

empty_jsinfo_fixture = rule(
    implementation = _empty_jsinfo_impl,
    attrs = js_runfiles_groups.RULE_ATTRS | {
        "emit_companion": attr.bool(default = True),
    },
)

def _directory_entry_impl(ctx):
    directory = ctx.actions.declare_directory(ctx.label.name + "_dir")
    ctx.actions.run_shell(
        outputs = [directory],
        command = "echo 'console.log(1)' > %s/index.js" % directory.path,
    )
    return [
        DefaultInfo(files = depset([directory])),
        DirectoryPathInfo(directory = directory, path = "index.js"),
    ]

directory_entry_point = rule(
    implementation = _directory_entry_impl,
)

def _foreign_rgi_impl(ctx):
    extra = ctx.actions.declare_file(ctx.label.name + "_extra.txt")
    rf_file = ctx.actions.declare_file(ctx.label.name + "_rf.txt")
    ctx.actions.write(extra, "extra")
    ctx.actions.write(rf_file, "rf")
    runfiles = ctx.runfiles(files = [rf_file])
    entry = runfiles_groups.entry(
        name = ctx.label,
        content = runfiles,
    )
    return [
        DefaultInfo(files = depset([extra]), runfiles = runfiles),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [entry]),
            executable_group = None,
        ),
    ]

foreign_rgi_data = rule(
    implementation = _foreign_rgi_impl,
)

def _foreign_symlinks_impl(ctx):
    f = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(f, "s")
    runfiles = ctx.runfiles(
        files = [f],
        symlinks = {"foreign/symlink": f},
        root_symlinks = {"root/symlink": f},
    )
    return [DefaultInfo(files = depset([f]), runfiles = runfiles)]

foreign_symlinks = rule(implementation = _foreign_symlinks_impl)

def _foreign_files_order_impl(ctx):
    a = ctx.actions.declare_file(ctx.label.name + "_a.txt")
    b = ctx.actions.declare_file(ctx.label.name + "_b.txt")
    ctx.actions.write(a, "a")
    ctx.actions.write(b, "b")
    return [DefaultInfo(files = depset([a, b], order = ctx.attr.order))]

foreign_files_order = rule(
    implementation = _foreign_files_order_impl,
    attrs = {"order": attr.string(mandatory = True, values = ["preorder", "postorder", "topological", "default"])},
)

def _foreign_rgi_mixed_impl(ctx):
    f1 = ctx.actions.declare_file(ctx.label.name + "_files.txt")
    f2 = ctx.actions.declare_file(ctx.label.name + "_rf.txt")
    ctx.actions.write(f1, "1")
    ctx.actions.write(f2, "2")
    e1 = runfiles_groups.entry(name = ctx.label, content = depset([f1]))
    e2 = runfiles_groups.entry(
        name = "foreign#mixed",
        content = ctx.runfiles(files = [f2]),
        kind = "docs",
        rank = 50,
        weight = 3,
        merge_affinity = "foreign",
    )
    return [
        DefaultInfo(files = depset([f1]), runfiles = ctx.runfiles(files = [f2])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [e1, e2]),
            executable_group = None,
        ),
    ]

foreign_rgi_mixed = rule(implementation = _foreign_rgi_mixed_impl)

def _foreign_dup_names_impl(ctx):
    a = ctx.actions.declare_file(ctx.label.name + "_a.txt")
    b = ctx.actions.declare_file(ctx.label.name + "_b.txt")
    ctx.actions.write(a, "a")
    ctx.actions.write(b, "b")
    e1 = runfiles_groups.entry(
        name = "foreign#dup",
        content = depset([a]),
        kind = "docs",
        rank = 10,
        weight = 1,
        merge_affinity = "a",
    )
    e2 = runfiles_groups.entry(
        name = "foreign#dup",
        content = depset([b]),
        kind = "",
        rank = 4,
        do_not_merge = True,
        weight = 8,
        merge_affinity = "b",
    )
    return [
        DefaultInfo(files = depset(), runfiles = ctx.runfiles(files = [a, b])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [e1, e2]),
            executable_group = None,
        ),
    ]

foreign_dup_names = rule(implementation = _foreign_dup_names_impl)

def _foreign_protected_impl(ctx):
    f = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(f, "p")
    entry = runfiles_groups.entry(
        name = "foreign#protected",
        content = depset([f]),
        kind = "docs",
        rank = runfiles_groups.RANK_FOUNDATION,
        do_not_merge = True,
    )
    return [
        DefaultInfo(files = depset(), runfiles = ctx.runfiles(files = [f])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [entry]),
            executable_group = None,
        ),
    ]

foreign_protected = rule(implementation = _foreign_protected_impl)

def _opaque_jsinfo_impl(ctx):
    shared = ctx.file.shared
    own = ctx.actions.declare_file(ctx.label.name + "_own.js")
    ctx.actions.write(own, "")
    sources = depset([own, shared])
    return [
        DefaultInfo(files = depset([own, shared]), runfiles = ctx.runfiles(files = [own, shared])),
        js_info(
            target = ctx.label,
            sources = sources,
            transitive_sources = sources,
            types = depset(),
            transitive_types = depset(),
            npm_sources = depset(),
        ),
    ]

opaque_jsinfo = rule(
    implementation = _opaque_jsinfo_impl,
    attrs = {
        "shared": attr.label(allow_single_file = True, mandatory = True),
    },
)

def _foreign_rgi_named_outputs_impl(ctx):
    extra = ctx.actions.declare_file(ctx.label.name + "_out.txt")
    ctx.actions.write(extra, "out")
    entry = runfiles_groups.entry(
        name = "foreign#custom_outs",
        content = depset([extra]),
        kind = "docs",
    )
    return [
        DefaultInfo(files = depset([extra]), runfiles = ctx.runfiles()),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [entry]),
            executable_group = None,
        ),
    ]

foreign_rgi_named_outputs = rule(implementation = _foreign_rgi_named_outputs_impl)

def _foreign_entry_overlap_impl(ctx):
    entry_js = ctx.actions.declare_file(ctx.label.name + "_main.js")
    ctx.actions.write(entry_js, "console.log(1);\n")
    entry = runfiles_groups.entry(
        name = "foreign#entry",
        content = depset([entry_js]),
        kind = "docs",
    )
    return [
        DefaultInfo(files = depset([entry_js]), runfiles = ctx.runfiles(files = [entry_js])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [entry]),
            executable_group = None,
        ),
    ]

foreign_entry_overlap = rule(implementation = _foreign_entry_overlap_impl)

def _node_path_toolchain_impl(_ctx):
    return [platform_common.ToolchainInfo(
        nodeinfo = struct(
            node = None,
            node_path = "/usr/bin/node",
            npm = None,
            npm_path = "",
            npm_sources = depset(),
        ),
    )]

node_path_toolchain = rule(implementation = _node_path_toolchain_impl)

_custom_grouped_binary_rule = rule(
    implementation = js_binary_lib.implementation,
    attrs = js_binary_lib.attrs,
    executable = True,
    toolchains = js_binary_lib.toolchains,
)

_custom_grouped_rule_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = js_binary_lib.attrs,
    test = True,
    toolchains = js_binary_lib.toolchains,
)

def custom_grouped_binary(**kwargs):
    _custom_grouped_binary_rule(
        enable_runfiles = select({
            Label("@bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

def custom_grouped_test(**kwargs):
    _custom_grouped_rule_test(
        enable_runfiles = select({
            Label("@bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

