"""Rules for creating container image layers from js_binary targets

For example, this js_image_layer target outputs `node_modules.tar` and `app.tar` with `/app` prefix.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_image_layer")

js_image_layer(
    name = "layers",
    binary = "//label/to:js_binary",
    root = "/app",
)
```
"""

load("@aspect_bazel_lib//lib:tar.bzl", "tar_lib")
load("@bazel_skylib//lib:paths.bzl", "paths")

_DEFAULT_LAYER_GROUPS = {
    "node": "/js/private/node-patches/|/bin/nodejs/",
    "package_store_3p": "/\\.aspect_rules_js/(?!.*@0\\.0\\.0).*/node_modules",
    "package_store_1p": "\\.aspect_rules_js/.*@0\\.0\\.0/node_modules",
    "node_modules": "/node_modules/",
    "app": "",  # empty means just match anything.
}

_DOC = """Create container image layers from js_binary targets.

By design, js_image_layer doesn't have any preference over which rule assembles the container image.
This means the downstream rule (`oci_image` from [rules_oci](https://github.com/bazel-contrib/rules_oci)
or `container_image` from [rules_docker](https://github.com/bazelbuild/rules_docker)) must
set a proper `workdir` and `cmd` to for the container work.

A proper `cmd` usually looks like /`[ js_image_layer 'root' ]`/`[ package name of js_image_layer 'binary' target ]/[ name of js_image_layer 'binary' target ]`,
unless you have a custom launcher script that invokes the entry_point of the `js_binary` in a different path.

On the other hand, `workdir` has to be set to the "runfiles tree root" which would be exactly `cmd` **but with `.runfiles/[ name of the workspace ]` suffix**.
If using bzlmod then name of the local workspace is always `_main`. If bzlmod is not enabled then the name of the local workspace, if not otherwise specified
in the `WORKSPACE` file, is `__main__`. If `workdir` is not set correctly, some attributes such as `chdir` might not work properly.

js_image_layer creates up to 5 layers depending on what files are included in the runfiles of the provided
`binary` target.

1. `node` layer contains the Node.js toolchain
2. `package_store_3p` layer contains all 3p npm deps in the `node_modules/.aspect_rules_js` package store
3. `package_store_1p` layer contains all 1p npm deps in the `node_modules/.aspect_rules_js` package store
4. `node_modules` layer contains all `node_modules/*` symlinks which point into the package store
5. `app` layer contains all files that don't fall into any of the above layers

If no files are found in the runfiles of the `binary` target for one of the layers above, that
layer is not generated. All generated layer tarballs are provided as `DefaultInfo` files.

> The rules_js `node_modules/.aspect_rules_js` package store follows the same pattern as the pnpm
> `node_modules/.pnpm` virtual store. For more information see https://pnpm.io/symlinked-node-modules-structure.

js_image_layer also provides an `OutputGroupInfo` with outputs for each of the layers above which
can be used to reference an individual layer with using `filegroup` with `output_group`. For example,

```starlark
js_image_layer(
    name = "layers",
    binary = ":bin",
    root = "/app",
)

filegroup(
    name = "app_tar",
    srcs = [":layers"],
    output_group = "app",
)
```

> WARNING: The structure of the generated layers are not subject to semver guarantees and may change without a notice.
> However, it is guaranteed to work when all generated layers are provided together in the order specified above.

js_image_layer supports transitioning to specific `platform` to allow building multi-platform container images.

**A partial example using rules_oci with transition to linux/amd64 platform.**

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_image_layer")
load("@rules_oci//oci:defs.bzl", "oci_image")

js_binary(
    name = "bin",
    entry_point = "main.js",
)

platform(
    name = "amd64_linux",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
)

js_image_layer(
    name = "layers",
    binary = ":bin",
    platform = ":amd64_linux",
    root = "/app",
)

oci_image(
    name = "image",
    cmd = ["/app/bin"],
    entrypoint = ["bash"],
    tars = [
        ":layers"
    ],
    workdir = select({
        "@aspect_bazel_lib//lib:bzlmod": "/app/bin.runfiles/_main",
        "//conditions:default": "/app/bin.runfiles/__main__",
    }),
)
```

**A partial example using rules_oci to create multi-platform images.**

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_image_layer")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_image_index")

js_binary(
    name = "bin",
    entry_point = "main.js",
)

[
    platform(
        name = "linux_{}".format(arch),
        constraint_values = [
            "@platforms//os:linux",
            "@platforms//cpu:{}".format(arch if arch != "amd64" else "x86_64"),
        ],
    )

    js_image_layer(
        name = "{}_layers".format(arch),
        binary = ":bin",
        platform = ":linux_{arch}",
        root = "/app",
    )

    oci_image(
        name = "{}_image".format(arch),
        cmd = ["/app/bin"],
        entrypoint = ["bash"],
        tars = [
            ":{}_layers".format(arch)
        ],
        workdir = select({
            "@aspect_bazel_lib//lib:bzlmod": "/app/bin.runfiles/_main",
            "//conditions:default": "/app/bin.runfiles/__main__",
        }),
    )

    for arch in ["amd64", "arm64"]
]

oci_image_index(
    name = "image",
    images = [
        ":arm64_image",
        ":amd64_image"
    ]
)
```

**An example using legacy rules_docker**

See `e2e/js_image_docker` for full example.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_image_layer")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")

js_binary(
    name = "bin",
    data = [
        "//:node_modules/args-parser",
    ],
    entry_point = "main.js",
)

js_image_layer(
    name = "layers",
    binary = ":bin",
    root = "/app",
    visibility = ["//visibility:__pkg__"],
)

filegroup(
    name = "node_tar",
    srcs = [":layers"],
    output_group = "node",
)

container_layer(
    name = "node_layer",
    tars = [":node_tar"],
)

filegroup(
    name = "package_store_3p_tar",
    srcs = [":layers"],
    output_group = "package_store_3p",
)

container_layer(
    name = "package_store_3p_layer",
    tars = [":package_store_3p_tar"],
)

filegroup(
    name = "package_store_1p_tar",
    srcs = [":layers"],
    output_group = "package_store_1p",
)

container_layer(
    name = "package_store_1p_layer",
    tars = [":package_store_1p_tar"],
)

filegroup(
    name = "node_modules_tar",
    srcs = [":layers"],
    output_group = "node_modules",
)

container_layer(
    name = "node_modules_layer",
    tars = [":node_modules_tar"],
)

filegroup(
    name = "app_tar",
    srcs = [":layers"],
    output_group = "app",
)

container_layer(
    name = "app_layer",
    tars = [":app_tar"],
)

container_image(
    name = "image",
    cmd = ["/app/bin"],
    entrypoint = ["bash"],
    layers = [
        ":node_layer",
        ":package_store_3p_layer",
        ":package_store_1p_layer",
        ":node_modules_layer",
        ":app_layer",
    ],
    workdir = select({
        "@aspect_bazel_lib//lib:bzlmod": "/app/bin.runfiles/_main",
        "//conditions:default": "/app/bin.runfiles/__main__",
    }),
)
```


## Performance

For better performance, it is recommended to split the large parts of a `js_binary` to have a separate layer.

The matching order for layer groups is as follows:

1. `layer_groups` are checked in order first
2. If no match is found for `layer_groups`, the `default layer groups` are checked.
3. Any remaining files are placed into the app layer.

The default layer groups are as follows and always created.

```
{
    "node": "/js/private/node-patches/|/bin/nodejs/",
    "package_store_1p": "\\.aspect_rules_js/.*@0\\.0\\.0/node_modules",
    "package_store_3p": "\\.aspect_rules_js/.*/node_modules",
    "node_modules": "/node_modules/",
    "app": "", # empty means just match anything.
}
```

"""

# BAZEL_BINDIR has to be set to '.' so that js_binary preserves the PWD when running inside container.
# See https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
# for why this is needed.
_LAUNCHER_PREABMLE = """\
#!/usr/bin/env bash

export BAZEL_BINDIR="."

# patched by js_image_layer for hermeticity
"""

def _write_laucher(ctx, real_binary):
    "Creates a call-through shell entrypoint which sets BAZEL_BINDIR to '.' then immediately invokes the original entrypoint."
    launcher = ctx.actions.declare_file("%s_launcher" % ctx.label.name)

    substitutions = {
        "#!/usr/bin/env bash": _LAUNCHER_PREABMLE,
        'export JS_BINARY__BINDIR="%s"' % real_binary.root.path: 'export JS_BINARY__BINDIR="$(pwd)"',
        'export JS_BINARY__TARGET_CPU="%s"' % ctx.expand_make_variables("", "$(TARGET_CPU)", {}): 'export JS_BINARY__TARGET_CPU="$(uname -m)"',
    }
    substitutions['export JS_BINARY__BINDIR="%s"' % ctx.bin_dir.path] = 'export JS_BINARY__BINDIR="$(pwd)"'

    ctx.actions.expand_template(
        template = real_binary,
        output = launcher,
        substitutions = substitutions,
        is_executable = True,
    )
    return launcher

def _run_splitter(ctx, runfiles_dir, files, entries_json, layer_groups):
    ownersplit = ctx.attr.owner.split(":")
    if len(ownersplit) != 2 or not ownersplit[0].isdigit() or not ownersplit[1].isdigit():
        fail("owner attribute should be in `0:0` `int:int` format.")

    VARIABLES = ""
    PICK_STATEMENTS = ""
    WRITE_STATEMENTS = ""

    splitter_outputs = []
    expected_layer_groups = []

    for name, match in layer_groups.items():
        mtree = ctx.actions.declare_file("{}_{}.mtree".format(ctx.label.name, name))
        unused_inputs = ctx.actions.declare_file("{}_{}_unused_inputs.txt".format(ctx.label.name, name))
        splitter_outputs.extend([mtree, unused_inputs])
        VARIABLES += """
    const {name}_re = new RegExp({});
    const {name}mtree = new Set(["#mtree"]);
    const {name}unusedinputs = createWriteStream({});
""".format(json.encode(match), json.encode(unused_inputs.path), name = name)

        STMT = "else if" if PICK_STATEMENTS != "" else "if"

        IF_STMT = "%s (%s_re.test(key))" % (STMT, name)

        # Empty match means, match anything, same as .* but faster.
        if match == "":
            IF_STMT = "%s (true)" % (STMT)

        PICK_STATEMENTS += """
%s {
    mtree = %smtree;
%s
}
        """ % (
            IF_STMT,
            name,
            "\n".join([
                "    %sunusedinputs.write(destBuf);" % oname
                for oname in layer_groups.keys()
                if oname != name
            ]),
        )

        WRITE_STATEMENTS += """writeFile("%s", Array.from(%smtree).sort().concat(["\\n"]).join("\\n")),\n""" % (mtree.path, name)

        expected_layer_groups.append((name, mtree, unused_inputs))

    # Final else {} to discard a file if it doesn't match any of the layer groups.
    PICK_STATEMENTS += """
else {
%s
    continue
}""" % (
        "\n".join([
            "    %sunusedinputs.write(destBuf);" % oname
            for oname in layer_groups.keys()
        ])
    )

    unused_inputs = ctx.actions.declare_file("{}_splitter_unused_inputs.txt".format(ctx.label.name))
    splitter_outputs.append(unused_inputs)

    splitter = ctx.actions.declare_file("{}_js_image_layer_splitter.mjs".format(ctx.label.name))
    ctx.actions.expand_template(
        template = ctx.file._splitter,
        output = splitter,
        is_executable = True,
        substitutions = {
            "{{UID}}": ownersplit[0],
            "{{GID}}": ownersplit[1],
            "{{RUNFILES_DIR}}": runfiles_dir,
            "{{REPO_NAME}}": ctx.workspace_name,
            "{{ENTRIES}}": entries_json.path,
            "'{{PRESERVE_SYMLINKS}}'": json.encode(ctx.attr.preserve_symlinks),
            "{{UNUSED_INPUTS}}": unused_inputs.path,
            "{{DIRECTORY_MODE}}": ctx.attr.directory_mode,
            "{{FILE_MODE}}": ctx.attr.file_mode,
            "/*{{VARIABLES}}*/": VARIABLES,
            "/*{{PICK_STATEMENTS}}*/": PICK_STATEMENTS,
            "/*{{WRITE_STATEMENTS}}*/": WRITE_STATEMENTS,
        },
    )

    inputs = depset(
        [entries_json, splitter],
        transitive = [files],
    )

    nodeinfo = ctx.attr._current_node[platform_common.ToolchainInfo].nodeinfo
    if hasattr(nodeinfo, "node"):
        node_exec = nodeinfo.node
    else:
        # TODO(3.0): drop support for deprecated toolchain attributes
        node_exec = nodeinfo.target_tool_path
    ctx.actions.run(
        inputs = inputs,
        arguments = [splitter.path],
        unused_inputs_list = unused_inputs,
        outputs = splitter_outputs,
        executable = node_exec,
        progress_message = "Computing Layer Groups %{label}",
        mnemonic = "JsImageLayerGroups",
    )

    return expected_layer_groups

# This function exactly same as the one from "@aspect_bazel_lib//lib:paths.bzl"
# except that it takes workspace_name directly instead of the ctx object.
# Reason is the performance of Args.add_all closures where we use this function.
# https://bazel.build/rules/lib/builtins/Args#add_all `allow_closure` explains this.
def _to_rlocation_path(file, workspace):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return workspace + "/" + file.short_path

def _repo_mapping_manifest(files_to_run):
    return getattr(files_to_run, "repo_mapping_manifest", None)

_ENTRY = '"%s":{"dest":%s,"root":"%s","is_external":%s,"is_source":%s,"repo_name":"%s"},\n%s:"%s"'

def _js_image_layer_impl(ctx):
    if ctx.attr.generate_empty_layers:
        # buildifier: disable=print
        print("The `generate_empty_layers` attribute is deprecated and will be removed in the next major release. Its behavior is now implicitly `True`")
    if len(ctx.attr.binary) != 1:
        fail("binary attribute has more than one transition")

    binary_default_info = ctx.attr.binary[0][DefaultInfo]
    binary_label = ctx.attr.binary[0].label

    binary_path = "./" + paths.join(ctx.attr.root.lstrip("./").lstrip("/"), binary_label.package, binary_label.name)
    runfiles_dir = binary_path + ".runfiles"

    launcher = _write_laucher(ctx, binary_default_info.files_to_run.executable)

    repo_mapping = _repo_mapping_manifest(binary_default_info.files_to_run)

    runfiles_plus_files = depset(
        transitive = [binary_default_info.files, binary_default_info.default_runfiles.files],
    )

    # copy workspace name here just in case to prevent ctx  to be transferred to execution phase.
    workspace_name = str(ctx.workspace_name)

    # be careful about what you access outside of the function closure. accessing objects
    # such as ctx within this function will make it significantly slower.
    def map_entry(f, expander):
        runfiles_dest = runfiles_dir + "/" + _to_rlocation_path(f, workspace_name)
        path = json.encode(f.path)
        if not f.is_directory:
            return _ENTRY % (
                runfiles_dest,
                path,
                f.root.path,
                "true" if f.owner.repo_name != "" else "false",
                "true" if f.is_source else "false",
                f.owner.repo_name,
                # To avoid O(N ^ N) complexity when searching for entries by their destination
                # the map also has to have entries by their path on bazel-out,
                path,
                runfiles_dest,
            )
        else:
            # Directory expansion needs to happen during execution phase to
            # correctly track the contents of the treeartifact.
            tree = expander.expand(f)
            contents = ""
            for f in tree:
                # only add command after first iteration.
                if contents:
                    contents += ","

                runfiles_dest = runfiles_dest + f.tree_relative_path
                path = path + f.tree_relative_path
                contents += _ENTRY % (
                    runfiles_dest,
                    path,
                    f.root.path,
                    "true" if f.owner.repo_name != "" else "false",
                    "true" if f.is_source else "false",
                    f.owner.repo_name,
                    # To avoid O(N ^ N) complexity when searching for entries by their destination
                    # the map also has to have entries by their path on bazel-out,
                    path,
                    runfiles_dest,
                )
            return contents

    entries = ctx.actions.args()
    entries.set_param_file_format("multiline")

    entries.add("{")
    entries.add_joined(
        [binary_path, {"dest": launcher.path, "root": launcher.root.path}],
        join_with = ":",
        map_each = json.encode,
    )
    entries.add_all(
        runfiles_plus_files,
        expand_directories = True,
        map_each = map_entry,
        allow_closure = True,
        before_each = ",",
    )
    entries.add(",")

    # shell launcher generated by js_binary contains non-reproducible information swap it out with the sanitized one.
    binary_path_under_runfiles = runfiles_dir + "/" + _to_rlocation_path(binary_default_info.files_to_run.executable, workspace_name)
    entries.add_joined(
        [binary_path_under_runfiles, {"dest": launcher.path, "root": launcher.root.path}],
        join_with = ":",
        map_each = json.encode,
    )

    if repo_mapping:
        entries.add(",")
        entries.add_joined(
            [runfiles_dir + "/" + "_repo_mapping", {"dest": repo_mapping.path, "root": repo_mapping.root.path}],
            join_with = ":",
            map_each = json.encode,
        )
    entries.add("}")

    entries_json = ctx.actions.declare_file("{}_entries.json".format(ctx.label.name))
    ctx.actions.write(entries_json, content = entries)

    # Ordering of these matter.
    layer_groups = dict()
    for key in ctx.attr.layer_groups:
        # Only add if the key is not in the default layer groups since we already handled the collision below.
        if key not in _DEFAULT_LAYER_GROUPS:
            layer_groups[key] = ctx.attr.layer_groups[key]

    for key, value in _DEFAULT_LAYER_GROUPS.items():
        # if the key is provided by the user, use it, otherwise use the default.
        if key in ctx.attr.layer_groups:
            layer_groups[key] = ctx.attr.layer_groups[key]
        else:
            layer_groups[key] = value

    layer_groups_gen = _run_splitter(ctx, runfiles_dir, runfiles_plus_files, entries_json, layer_groups)

    tarinfo = ctx.toolchains[tar_lib.toolchain_type].tarinfo

    outputs = []
    output_groups = dict()
    compress = "" if ctx.attr.compression == "none" else ctx.attr.compression
    for typ, mtree, unused_inputs in layer_groups_gen:
        ext = tar_lib.common.compression_to_extension[compress] if compress else ""
        output = ctx.actions.declare_file("%s_%s%s" % (ctx.label.name, typ, ext))

        # add the layer group to outputgroupinfo and defaultinfo
        outputs.append(output)
        output_groups[typ] = depset([output])

        args = ctx.actions.args()
        args.add("--create")
        args.add("--file")
        args.add(output)
        tar_lib.common.add_compression_args(compress, args)
        args.add(mtree, format = "@%s")

        ctx.actions.run(
            inputs = depset(
                ([repo_mapping] if repo_mapping else []) + [entries_json, launcher, mtree, unused_inputs],
                transitive = [runfiles_plus_files],
            ),
            arguments = [args],
            executable = tarinfo.binary,
            unused_inputs_list = unused_inputs,
            env = tarinfo.default_env,
            outputs = [output],
            mnemonic = "JsImageLayer",
            progress_message = "JsImageLayer " + typ + " %{label}",
            toolchain = "@aspect_bazel_lib//lib:tar_toolchain_type",
        )

    return [
        DefaultInfo(files = depset(outputs)),
        OutputGroupInfo(**output_groups),
    ]

def _js_image_layer_transition_impl(settings, attr):
    # buildifier: disable=unused-variable
    _ignore = (settings)
    if not attr.platform:
        return {}
    return {
        "//command_line_option:platforms": str(attr.platform),
    }

_js_image_layer_transition = transition(
    implementation = _js_image_layer_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:platforms"],
)

js_image_layer_lib = struct(
    implementation = _js_image_layer_impl,
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_splitter": attr.label(
            default = "//js/private:js_image_layer.mjs",
            allow_single_file = True,
        ),
        "_current_node": attr.label(
            default = "@nodejs_toolchains//:resolved_toolchain",
            cfg = "exec",
        ),
        "binary": attr.label(
            mandatory = True,
            cfg = _js_image_layer_transition,
            executable = True,
            doc = "Label to an js_binary target",
        ),
        "root": attr.string(
            doc = "Path where the files from js_binary will reside in. eg: /apps/app1 or /app",
        ),
        "owner": attr.string(
            doc = "Owner of the entries, in `GID:UID` format. By default `0:0` (root, root) is used.",
            default = "0:0",
        ),
        "directory_mode": attr.string(
            doc = "Mode of the directories, in `octal` format. By default `0755` is used.",
            default = "0755",
        ),
        "file_mode": attr.string(
            doc = "Mode of the files, in `octal` format. By default `0555` is used.",
            default = "0555",
        ),
        "compression": attr.string(
            doc = "Compression algorithm. See https://github.com/bazel-contrib/bazel-lib/blob/bdc6ade0ba1ebe88d822bcdf4d4aaa2ce7e2cd37/lib/private/tar.bzl#L29-L39",
            values = tar_lib.common.accepted_compression_types + ["none"],
            default = "gzip",
        ),
        "platform": attr.label(
            doc = "Platform to transition.",
        ),
        "generate_empty_layers": attr.bool(
            # TODO(3.0): remove this attribute.
            doc = """DEPRECATED. An empty layer is always generated if the layer group have no matching files.""",
            default = False,
        ),
        "preserve_symlinks": attr.string(
            doc = """Preserve symlinks for entries matching the pattern.
By default symlinks within the `node_modules` is preserved.
""",
            default = ".*/node_modules/.*",
        ),
        "layer_groups": attr.string_dict(
            doc = """Layer groups to create.
These are utilized to categorize files into distinct layers, determined by their respective paths.
The expected format for each entry is "<key>": "<value>", where <key> MUST be a valid Bazel and
JavaScript identifier (alphanumeric characters), and <value> MAY be either an empty string (signifying a universal match)
or a valid regular expression.""",
        ),
    },
)

js_image_layer = rule(
    implementation = js_image_layer_lib.implementation,
    attrs = js_image_layer_lib.attrs,
    doc = _DOC,
    toolchains = [
        tar_lib.toolchain_type,
        "@rules_nodejs//nodejs:toolchain_type",
    ],
)
