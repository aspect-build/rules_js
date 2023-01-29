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

load("@aspect_bazel_lib//lib:paths.bzl", "to_manifest_path")
load("@bazel_skylib//lib:paths.bzl", "paths")

_doc = """Create container image layers from js_binary targets.

js_image_layer supports transitioning to specific platform for cross-compiling.

A partial example using rules_oci with transition to linux/amd64 platform.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_image_layer")
load("@contrib_rules_oci//oci:defs.bzl", "oci_image")

js_binary(
    name = "binary",
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
    binary = ":binary",
    platform = ":amd64_linux",
    root = "/app"
)

oci_image(
    name = "image",
    cmd = ["/app/main"],
    entrypoint = ["bash"],
    tars = [
        ":layers"
    ]
)
```

An example using legacy rules_docker

See `e2e/js_image_rules_docker` for full example.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_binary", "js_image_layer")
load("@io_bazel_rules_docker//container:container.bzl", "container_image")

js_binary(
    name = "main",
    data = [
        "//:node_modules/args-parser",
    ],
    entry_point = "main.js",
)


js_image_layer(
    name = "layers",
    binary = ":main",
    root = "/app",
    visibility = ["//visibility:__pkg__"],
)

filegroup(
    name = "app_tar", 
    srcs = [":layers"], 
    output_group = "app"
)
container_layer(
    name = "app_layer",
    tars = [":app_tar"],
)

filegroup(
    name = "node_modules_tar", 
    srcs = [":layers"], 
    output_group = "node_modules"
)
container_layer(
    name = "node_modules_layer",
    tars = [":node_modules_tar"],
)

container_image(
    name = "image",
    cmd = ["/app/main"],
    entrypoint = ["bash"],
    layers = [
        ":app_layer",
        ":node_modules_layer",
    ],
)
```
"""

# BAZEL_BINDIR has to be set to '.' so that js_binary preserves the PWD when running inside container.
# See https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
# for why this is needed.
_LAUNCHER_TMPL = """
export BAZEL_BINDIR=.
source {executable_path}
"""

def _write_laucher(ctx, executable_path):
    "Creates a call-through shell entrypoint which sets BAZEL_BINDIR to '.' then immediately invokes the original entrypoint."
    launcher = ctx.actions.declare_file("%s_launcher.sh" % ctx.label.package)
    ctx.actions.write(
        output = launcher,
        content = _LAUNCHER_TMPL.format(executable_path = executable_path),
        is_executable = True,
    )
    return launcher

def _runfile_path(ctx, file, runfiles_dir):
    return paths.join(runfiles_dir, to_manifest_path(ctx, file))

def _runfiles_dir(root, default_info):
    manifest = default_info.files_to_run.runfiles_manifest

    runfiles = manifest.short_path.replace(manifest.basename, "")[:-1]
    return paths.join(root, runfiles.replace(".sh", ""))

def _js_image_layer_impl(ctx):
    if len(ctx.attr.binary) != 1:
        fail("binary attribute has more than one transition")

    default_info = ctx.attr.binary[0][DefaultInfo]
    runfiles_dir = _runfiles_dir(ctx.attr.root, default_info)

    executable = default_info.files_to_run.executable
    executable_path = paths.replace_extension(paths.join(ctx.attr.root, executable.short_path), "")
    real_executable_path = _runfile_path(ctx, executable, runfiles_dir)
    launcher = _write_laucher(ctx, real_executable_path)

    files = {}

    files[executable_path] = {"dest": launcher.path, "root": launcher.root.path}

    for file in depset(transitive = [default_info.files, default_info.default_runfiles.files]).to_list():
        destination = _runfile_path(ctx, file, runfiles_dir)
        entry = {"dest": file.path, "root": file.root.path, "is_source": file.is_source, "is_directory": file.is_directory}
        if destination == real_executable_path:
            entry["remove_non_hermetic_lines"] = True
        files[destination] = entry

    entries = ctx.actions.declare_file("{}_entries.json".format(ctx.label.name))
    ctx.actions.write(entries, content = json.encode(files))

    extension = ".tar"

    if ctx.attr.compression == "gzip":
        extension = ".tar.gz"

    app = ctx.actions.declare_file("{name}_app{extension}".format(name = ctx.label.name, extension = extension))
    node_modules = ctx.actions.declare_file("{name}_node_modules{extension}".format(name = ctx.label.name, extension = extension))

    args = ctx.actions.args()
    args.add(entries)
    args.add(app)
    args.add(node_modules)
    args.add(ctx.attr.compression if ctx.attr.compression else "none")

    ctx.actions.run(
        inputs = depset([executable, launcher, entries], transitive = [default_info.files, default_info.default_runfiles.files]),
        outputs = [app, node_modules],
        arguments = [args],
        executable = ctx.executable._builder,
        progress_message = "JsImageLayer %{label}",
        env = {
            "BAZEL_BINDIR": ".",
        },
    )

    return [
        DefaultInfo(files = depset([app, node_modules])),
        OutputGroupInfo(app = depset([app]), node_modules = depset([node_modules])),
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

js_image_layer = rule(
    implementation = _js_image_layer_impl,
    doc = _doc,
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "binary": attr.label(mandatory = True, cfg = _js_image_layer_transition, doc = "Label to an js_binary target"),
        "root": attr.string(doc = "Path where the files from js_binary will reside in. eg: /apps/app1 or /app"),
        "compression": attr.string(doc = "Compression algorithm. Can be one of `gzip`, `none`.", values = ["gzip", "none"], default = "gzip"),
        "platform": attr.label(doc = "Platform to transition."),
        "_builder": attr.label(default = "//js/private:js_image_layer_builder", executable = True, cfg = "exec"),
    },
)
