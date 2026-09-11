"""Test-only producers for runfiles-group fixtures."""

load("@bazel_lib//lib:copy_to_bin.bzl", "COPY_FILE_TO_BIN_TOOLCHAINS")
load("@bazel_lib//lib:directory_path.bzl", "DirectoryPathInfo")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load("//js:libs.bzl", "js_binary_lib", "js_library_lib")
load("//js/private:js_info.bzl", "js_info")
load("//js/private:js_runfiles_groups.bzl", "js_runfiles_groups")
load("//npm:providers.bzl", "NpmPackageInfo")

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
    return [
        DefaultInfo(files = depset(), runfiles = ctx.runfiles()),
        js_info(
            target = ctx.label,
            sources = sources,
            types = types,
            transitive_sources = depset([s_direct, s_trans]),
            transitive_types = depset([t_direct, t_trans]),
            npm_sources = depset([npm_file]),
        ),
    ]

empty_jsinfo_fixture = rule(implementation = _empty_jsinfo_impl)

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

directory_entry_point = rule(implementation = _directory_entry_impl)

def _foreign_rgi_impl(ctx):
    extra = ctx.actions.declare_file(ctx.label.name + "_extra.txt")
    rf_file = ctx.actions.declare_file(ctx.label.name + "_rf.txt")
    ctx.actions.write(extra, "extra")
    ctx.actions.write(rf_file, "rf")
    runfiles = ctx.runfiles(files = [rf_file])
    return [
        DefaultInfo(files = depset([extra]), runfiles = runfiles),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [
                runfiles_groups.entry(name = ctx.label, content = runfiles),
            ]),
            executable_group = None,
        ),
    ]

foreign_rgi_data = rule(implementation = _foreign_rgi_impl)

def _foreign_symlinks_impl(ctx):
    f = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(f, "s")
    return [DefaultInfo(
        files = depset([f]),
        runfiles = ctx.runfiles(
            files = [f],
            symlinks = {"foreign/symlink": f},
            root_symlinks = {"root/symlink": f},
        ),
    )]

foreign_symlinks = rule(implementation = _foreign_symlinks_impl)

def _grouped_source_impl(ctx):
    src = ctx.file.src
    runfiles = ctx.runfiles(files = [src])
    return [
        DefaultInfo(files = depset([src]), runfiles = runfiles),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [
                runfiles_groups.entry(name = ctx.label, content = runfiles),
            ]),
            executable_group = None,
        ),
    ]

grouped_source = rule(
    implementation = _grouped_source_impl,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
)

def _single_output_exec_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(out, "#!/bin/true", is_executable = True)
    return [DefaultInfo(
        executable = out,
        files = depset([out]),
        runfiles = ctx.runfiles(files = [out]),
    )]

single_output_executable = rule(
    implementation = _single_output_exec_impl,
    executable = True,
)

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
    runfiles = ctx.runfiles(files = [f1, f2])
    return [
        DefaultInfo(files = depset([f1, f2]), runfiles = runfiles),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [
                runfiles_groups.entry(name = ctx.label, content = depset([f1])),
                runfiles_groups.entry(
                    name = "foreign#mixed",
                    content = ctx.runfiles(files = [f2]),
                    kind = "docs",
                    rank = 50,
                    weight = 3,
                    merge_affinity = "foreign",
                ),
            ]),
            executable_group = None,
        ),
    ]

foreign_rgi_mixed = rule(implementation = _foreign_rgi_mixed_impl)

def _foreign_protected_impl(ctx):
    f = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(f, "p")
    return [
        DefaultInfo(files = depset([f]), runfiles = ctx.runfiles(files = [f])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [
                runfiles_groups.entry(
                    name = "foreign#protected",
                    content = depset([f]),
                    kind = "docs",
                    rank = runfiles_groups.RANK_FOUNDATION,
                    do_not_merge = True,
                    merge_affinity = "foreign",
                ),
            ]),
            executable_group = None,
        ),
    ]

foreign_protected = rule(implementation = _foreign_protected_impl)

def _opaque_jsinfo_impl(ctx):
    own = ctx.actions.declare_file(ctx.label.name + "_own.js")
    ctx.actions.write(own, "own")
    shared = ctx.file.shared
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
    attrs = {"shared": attr.label(allow_single_file = True, mandatory = True)},
)

def _custom_npm_file_impl(ctx):
    pkg = ctx.actions.declare_file(ctx.label.name + "_pkg.js")
    ctx.actions.write(pkg, "pkg")
    return [
        DefaultInfo(files = depset([pkg]), runfiles = ctx.runfiles(files = [pkg])),
        js_info(
            target = ctx.label,
            sources = depset(),
            transitive_sources = depset(),
            types = depset(),
            transitive_types = depset(),
            npm_sources = depset([pkg]),
        ),
    ]

custom_npm_file = rule(implementation = _custom_npm_file_impl)

def _npm_package_info_data_impl(ctx):
    src = ctx.actions.declare_directory(ctx.label.name + "_dir")
    ctx.actions.run_shell(
        outputs = [src],
        command = "echo '{}' > %s/package.json && echo 'module.exports=1' > %s/index.js" % (src.path, src.path),
    )
    return [
        DefaultInfo(files = depset([src]), runfiles = ctx.runfiles()),
        NpmPackageInfo(
            package = ctx.attr.package,
            version = ctx.attr.version,
            src = src,
            npm_package_store_infos = depset(),
        ),
    ]

npm_package_info_data = rule(
    implementation = _npm_package_info_data_impl,
    attrs = {
        "package": attr.string(default = "fixture-pkg"),
        "version": attr.string(default = "1.0.0"),
    },
)

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

CopiedNodeIdentityInfo = provider(
    doc = "Test-only copied Node File.",
    fields = {"source": "Input File", "node": "Copied executable File"},
)

def _copied_node_toolchain_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "_node")
    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [out],
        command = "cp -f \"$1\" \"$2\" && chmod +x \"$2\"",
        arguments = [ctx.file.src.path, out.path],
        mnemonic = "CopyNodeFixture",
    )
    return [
        platform_common.ToolchainInfo(
            nodeinfo = struct(
                node = out,
                node_path = "",
                npm = None,
                npm_path = "",
                npm_sources = depset(),
            ),
        ),
        CopiedNodeIdentityInfo(source = ctx.file.src, node = out),
    ]

copied_node_toolchain = rule(
    implementation = _copied_node_toolchain_impl,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
)

def _rgi_passthrough_impl(ctx):
    dep = ctx.attr.dep
    runfiles = dep[DefaultInfo].default_runfiles
    providers = [DefaultInfo(files = dep[DefaultInfo].files, runfiles = runfiles)]
    if RunfilesGroupInfo in dep:
        providers.append(RunfilesGroupInfo(
            entries = dep[RunfilesGroupInfo].entries,
            executable_group = None,
        ))
    return providers

rgi_passthrough = rule(
    implementation = _rgi_passthrough_impl,
    attrs = {"dep": attr.label(mandatory = True)},
)

def _rgi_drop_impl(ctx):
    dep = ctx.attr.dep
    return [DefaultInfo(
        files = dep[DefaultInfo].files,
        runfiles = dep[DefaultInfo].default_runfiles,
    )]

rgi_drop = rule(
    implementation = _rgi_drop_impl,
    attrs = {"dep": attr.label(mandatory = True)},
)

def _rgi_aggregate_impl(ctx):
    trans = []
    runfiles = []
    for b in ctx.attr.binaries:
        runfiles.append(b[DefaultInfo].default_runfiles)
        if RunfilesGroupInfo in b:
            trans.append(b[RunfilesGroupInfo].entries)
    merged = ctx.runfiles()
    if runfiles:
        merged = runfiles[0].merge_all(runfiles[1:]) if len(runfiles) > 1 else runfiles[0]
    providers = [DefaultInfo(runfiles = merged)]
    if trans:
        providers.append(RunfilesGroupInfo(
            entries = runfiles_groups.collect(ctx, deps = [], data = [], own = [], transitive = trans),
            executable_group = None,
        ))
    return providers

rgi_aggregate = rule(
    implementation = _rgi_aggregate_impl,
    attrs = js_runfiles_groups.RULE_ATTRS | {
        "binaries": attr.label_list(mandatory = True),
    },
)

def _affinity_witness_impl(ctx):
    a = ctx.actions.declare_file(ctx.label.name + "_a.txt")
    b = ctx.actions.declare_file(ctx.label.name + "_b.txt")
    c = ctx.actions.declare_file(ctx.label.name + "_c.txt")
    ctx.actions.write(a, "a")
    ctx.actions.write(b, "b")
    ctx.actions.write(c, "c")
    if not js_runfiles_groups.is_enabled(ctx):
        return [
            DefaultInfo(files = depset([a, b, c]), runfiles = ctx.runfiles(files = [a, b, c])),
        ]
    rank = js_runfiles_groups.RANK_NPM_LINKS
    return [
        DefaultInfo(files = depset([a, b, c]), runfiles = ctx.runfiles(files = [a, b, c])),
        RunfilesGroupInfo(
            entries = runfiles_groups.entries(direct = [
                runfiles_groups.entry(
                    name = "aspect_rules_js#affinity_a",
                    content = depset([a]),
                    rank = rank,
                    weight = 2,
                    merge_affinity = js_runfiles_groups.AFFINITY,
                ),
                runfiles_groups.entry(
                    name = "aspect_rules_js#affinity_b",
                    content = depset([b]),
                    rank = rank,
                    weight = 3,
                    merge_affinity = js_runfiles_groups.AFFINITY,
                ),
                runfiles_groups.entry(
                    name = "foreign#affinity_c",
                    content = depset([c]),
                    rank = rank,
                    weight = 1,
                    merge_affinity = "foreign",
                ),
            ]),
            executable_group = None,
        ),
    ]

affinity_witness = rule(
    implementation = _affinity_witness_impl,
    attrs = js_runfiles_groups.RULE_ATTRS,
)

def _rebuilt_rgi_binary_impl(ctx):
    result = js_binary_lib.implementation(ctx)
    sentinel = ctx.actions.declare_file(ctx.label.name + "_sentinel.txt")
    ctx.actions.write(sentinel, "sentinel")
    default_info = None
    rgi = None
    others = []
    for p in result:
        p_type = type(p)
        if p_type == "DefaultInfo":
            default_info = p
        elif hasattr(p, "entries") and hasattr(p, "executable_group"):
            rgi = p
        else:
            others.append(p)
    if default_info == None:
        fail("js_binary_lib.implementation returned no DefaultInfo: {}".format([type(p) for p in result]))
    executable = None
    if default_info.files_to_run:
        executable = default_info.files_to_run.executable
    if executable == None and default_info.default_runfiles and default_info.default_runfiles.files:
        marker = "{}_/{}".format(ctx.label.name, ctx.label.name)
        for f in default_info.default_runfiles.files.to_list():
            if f.basename == ctx.label.name and marker in f.path:
                executable = f
                break
    if executable == None:
        fail("could not recover executable from DefaultInfo (files_to_run={}, files={})".format(
            default_info.files_to_run,
            [f.path for f in (default_info.files.to_list() if default_info.files else [])],
        ))
    new_runfiles = default_info.default_runfiles.merge(ctx.runfiles(files = [sentinel]))
    providers = others + [
        DefaultInfo(
            executable = executable,
            files = default_info.files,
            runfiles = new_runfiles,
        ),
    ]
    if rgi:
        extra = runfiles_groups.entry(
            name = js_runfiles_groups.FIRST_PARTY_GROUP,
            content = depset([sentinel]),
            kind = "first_party",
            rank = js_runfiles_groups.RANK_FIRST_PARTY_DEPS,
            merge_affinity = js_runfiles_groups.AFFINITY,
        )
        providers.append(RunfilesGroupInfo(
            entries = runfiles_groups.collect(
                ctx,
                deps = [],
                data = [],
                own = [extra],
                transitive = [rgi.entries],
            ),
            executable_group = rgi.executable_group,
        ))
    return providers

_rebuilt_rgi_binary_rule = rule(
    implementation = _rebuilt_rgi_binary_impl,
    attrs = js_binary_lib.attrs,
    executable = True,
    toolchains = js_binary_lib.toolchains,
)

def rebuilt_rgi_binary(**kwargs):
    _rebuilt_rgi_binary_rule(
        enable_runfiles = select({
            Label("@bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

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

_custom_grouped_library_rule = rule(
    implementation = js_library_lib.implementation,
    attrs = js_library_lib.attrs,
    provides = js_library_lib.provides,
    toolchains = COPY_FILE_TO_BIN_TOOLCHAINS,
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

def custom_grouped_library(**kwargs):
    _custom_grouped_library_rule(**kwargs)
