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
js_image_layer(<a href="#js_image_layer-name">name</a>, <a href="#js_image_layer-binary">binary</a>, <a href="#js_image_layer-compression">compression</a>, <a href="#js_image_layer-platform">platform</a>, <a href="#js_image_layer-root">root</a>)
</pre>

Create container image layers from js_binary targets.

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


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="js_image_layer-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="js_image_layer-binary"></a>binary |  Label to an js_binary target   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="js_image_layer-compression"></a>compression |  Compression algorithm. Can be one of <code>gzip</code>, <code>none</code>.   | String | optional | <code>"gzip"</code> |
| <a id="js_image_layer-platform"></a>platform |  Platform to transition.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="js_image_layer-root"></a>root |  Path where the files from js_binary will reside in. eg: /apps/app1 or /app   | String | optional | <code>""</code> |


