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
This means the downstream rule (`oci_image`, or `container_image` in this case) must set a proper `workdir` and `cmd` to for the container work.

A proper `cmd` usually looks like /`[ js_image_layer 'root' ]`/`[ package name of js_image_layer 'binary' target ]/[ name of js_image_layer 'binary' target ]`,
unless you have a custom launcher script that invokes the entry_point of the `js_binary` in a different path.

On the other hand, `workdir` has to be set to `runfiles tree root` which would be exactly `cmd` **but with `.runfiles/[ name of the workspace ]` suffix**.
If using bzlmod then name of the local workspace is always `_main`. If bzlmod is not enabled then the name of the local workspace, if not otherwise specified
in the `WORKSPACE` file, is `__main__`. If `workdir` is not set correctly, some attributes such as `chdir` might not work properly.

js_image_layer supports transitioning to specific `platform` to allow building multi-platform container images.

&gt; WARNING: Structure of the resulting layers are not subject to semver guarantees and may change without a notice. However, it is guaranteed to work when provided together in the `app` and `node_modules` order

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

See `e2e/js_image_rules_docker` for full example.

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
    name = "app_tar", 
    srcs = [":layers"], 
    output_group = "app",
)

container_layer(
    name = "app_layer",
    tars = [":app_tar"],
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

container_image(
    name = "image",
    cmd = ["/app/bin"],
    entrypoint = ["bash"],
    layers = [
        ":app_layer",
        ":node_modules_layer",
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
| <a id="js_image_layer-compression"></a>compression |  Compression algorithm. Can be one of <code>gzip</code>, <code>none</code>.   | String | optional | <code>"gzip"</code> |
| <a id="js_image_layer-owner"></a>owner |  Owner of the entries, in <code>GID:UID</code> format. By default <code>0:0</code> (root, root) is used.   | String | optional | <code>"0:0"</code> |
| <a id="js_image_layer-platform"></a>platform |  Platform to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="js_image_layer-root"></a>root |  Path where the files from js_binary will reside in. eg: /apps/app1 or /app   | String | optional | <code>""</code> |


<a id="js_image_layer_lib.implementation"></a>

## js_image_layer_lib.implementation

<pre>
js_image_layer_lib.implementation(<a href="#js_image_layer_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="js_image_layer_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


