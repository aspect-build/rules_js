<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for creating container image layers from js_binary targets

For example, this js_image_layer target outputs `node_modules.tar` and `app.tar` with `/app` prefix.

```starlark
load("@aspect_rules_js//js:defs.bzl", "js_image_layer")

js_image_layer(
    name = "layers",
    binary = "//label/to:js_binary",
    root = "/app",
)
```

<a id="js_image_layer"></a>

## js_image_layer

<pre>
js_image_layer(<a href="#js_image_layer-name">name</a>, <a href="#js_image_layer-binary">binary</a>, <a href="#js_image_layer-compression">compression</a>, <a href="#js_image_layer-owner">owner</a>, <a href="#js_image_layer-platform">platform</a>, <a href="#js_image_layer-root">root</a>)
</pre>

Create container image layers from js_binary targets.

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

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_image_layer-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="js_image_layer-binary"></a>binary |  Label to an js_binary target   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="js_image_layer-compression"></a>compression |  Compression algorithm. Can be one of `gzip`, `none`.   | String | optional |  `"gzip"`  |
| <a id="js_image_layer-owner"></a>owner |  Owner of the entries, in `GID:UID` format. By default `0:0` (root, root) is used.   | String | optional |  `"0:0"`  |
| <a id="js_image_layer-platform"></a>platform |  Platform to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="js_image_layer-root"></a>root |  Path where the files from js_binary will reside in. eg: /apps/app1 or /app   | String | optional |  `""`  |


<a id="js_image_layer_lib.implementation"></a>

## js_image_layer_lib.implementation

<pre>
js_image_layer_lib.implementation(<a href="#js_image_layer_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_image_layer_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


