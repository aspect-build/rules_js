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

load("@aspect_bazel_lib//lib:paths.bzl", "to_rlocation_path")
load("@bazel_skylib//lib:paths.bzl", "paths")

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
"""

# BAZEL_BINDIR has to be set to '.' so that js_binary preserves the PWD when running inside container.
# See https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
# for why this is needed.
_LAUNCHER_TMPL = """\
#!/usr/bin/env bash
export BAZEL_BINDIR=.
source {real_binary_path}
"""

def _write_laucher(ctx, real_binary_path):
    "Creates a call-through shell entrypoint which sets BAZEL_BINDIR to '.' then immediately invokes the original entrypoint."
    launcher = ctx.actions.declare_file("%s_launcher" % ctx.label.name)
    ctx.actions.write(
        output = launcher,
        content = _LAUNCHER_TMPL.format(real_binary_path = real_binary_path),
        is_executable = True,
    )
    return launcher

def _runfile_path(ctx, file, runfiles_dir):
    return paths.join(runfiles_dir, to_rlocation_path(ctx, file))

def _build_layer(ctx, type, all_entries_json, entries, inputs):
    if not entries:
        return None

    entries_json = ctx.actions.declare_file("{}_{}_entries.json".format(ctx.label.name, type))
    ctx.actions.write(entries_json, content = json.encode(entries))

    extension = "tar.gz" if ctx.attr.compression == "gzip" else "tar"
    output = ctx.actions.declare_file("{name}_{type}.{extension}".format(name = ctx.label.name, type = type, extension = extension))

    args = ctx.actions.args()
    args.add(all_entries_json)
    args.add(entries_json)
    args.add(output)
    args.add(ctx.attr.compression)
    args.add(ctx.attr.owner)

    ctx.actions.run(
        inputs = inputs + [all_entries_json, entries_json],
        outputs = [output],
        arguments = [args],
        executable = ctx.executable._builder,
        progress_message = "JsImageLayer %{label}",
        mnemonic = "JsImageLayer",
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

    return output

def _select_layer(layers, destination, file):
    is_node = file.owner.workspace_name != "" and "/bin/nodejs/" in destination
    is_js_patches = "/js/private/node-patches" in destination
    if is_node or is_js_patches:
        return layers.node
    is_package_store = "/.aspect_rules_js/" in destination
    if is_package_store:
        is_1p_dep = "@0.0.0/node_modules/" in destination
        if is_1p_dep:
            return layers.package_store_1p
        else:
            return layers.package_store_3p
    is_node_modules = "/node_modules/" in destination
    if is_node_modules:
        return layers.node_modules
    return layers.app

def _js_image_layer_impl(ctx):
    if len(ctx.attr.binary) != 1:
        fail("binary attribute has more than one transition")

    ownersplit = ctx.attr.owner.split(":")
    if len(ownersplit) != 2 or not ownersplit[0].isdigit() or not ownersplit[1].isdigit():
        fail("owner attribute should be in `0:0` `int:int` format.")

    binary_default_info = ctx.attr.binary[0][DefaultInfo]
    binary_label = ctx.attr.binary[0].label

    binary_path = paths.join(ctx.attr.root, binary_label.package, binary_label.name)
    runfiles_dir = binary_path + ".runfiles"

    real_binary_path = _runfile_path(ctx, binary_default_info.files_to_run.executable, runfiles_dir)
    launcher = _write_laucher(ctx, real_binary_path)

    all_files = depset(transitive = [binary_default_info.files, binary_default_info.default_runfiles.files])
    all_entries = {}

    layers = struct(
        node = struct(
            entries = {},
            inputs = [],
        ),
        package_store_3p = struct(
            entries = {},
            inputs = [],
        ),
        package_store_1p = struct(
            entries = {},
            inputs = [],
        ),
        node_modules = struct(
            entries = {},
            inputs = [],
        ),
        app = struct(
            entries = {binary_path: {"dest": launcher.path, "root": launcher.root.path}},
            inputs = [launcher],
        ),
    )

    for file in all_files.to_list():
        destination = _runfile_path(ctx, file, runfiles_dir)
        entry = {
            "dest": file.path,
            "root": file.root.path,
            "is_external": file.owner.workspace_name != "",
            "is_source": file.is_source,
            "is_directory": file.is_directory,
        }
        if destination == real_binary_path:
            entry["remove_non_hermetic_lines"] = True

        all_entries[destination] = entry

        layer = _select_layer(layers, destination, file)
        layer.entries[destination] = entry
        layer.inputs.append(file)

    all_entries_json = ctx.actions.declare_file("{}_all_entries.json".format(ctx.label.name))
    ctx.actions.write(all_entries_json, content = json.encode(all_entries))

    node = _build_layer(
        ctx,
        type = "node",
        all_entries_json = all_entries_json,
        entries = layers.node.entries,
        inputs = layers.node.inputs,
    )
    package_store_3p = _build_layer(
        ctx,
        type = "package_store_3p",
        all_entries_json = all_entries_json,
        entries = layers.package_store_3p.entries,
        inputs = layers.package_store_3p.inputs,
    )
    package_store_1p = _build_layer(
        ctx,
        type = "package_store_1p",
        all_entries_json = all_entries_json,
        entries = layers.package_store_1p.entries,
        inputs = layers.package_store_1p.inputs,
    )
    node_modules = _build_layer(
        ctx,
        type = "node_modules",
        all_entries_json = all_entries_json,
        entries = layers.node_modules.entries,
        inputs = layers.node_modules.inputs,
    )
    app = _build_layer(
        ctx,
        type = "app",
        all_entries_json = all_entries_json,
        entries = layers.app.entries,
        inputs = layers.app.inputs,
    )

    return [
        DefaultInfo(files = depset([i for i in [
            node,
            package_store_3p,
            package_store_1p,
            node_modules,
            app,
        ] if i])),
        OutputGroupInfo(
            node = depset([node]) if node else depset(),
            package_store_3p = depset([package_store_3p]) if package_store_3p else depset(),
            package_store_1p = depset([package_store_1p]) if package_store_1p else depset(),
            node_modules = depset([node_modules]) if node_modules else depset(),
            app = depset([app]) if app else depset(),
        ),
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
        "_builder": attr.label(
            default = "//js/private:js_image_layer_builder",
            executable = True,
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
        "compression": attr.string(
            doc = "Compression algorithm. Can be one of `gzip`, `none`.",
            values = ["gzip", "none"],
            default = "gzip",
        ),
        "platform": attr.label(
            doc = "Platform to transition.",
        ),
    },
)

js_image_layer = rule(
    implementation = js_image_layer_lib.implementation,
    attrs = js_image_layer_lib.attrs,
    doc = _DOC,
)
