# An example for rules_js + bazel-contrib/rules_oci

The `js_image_layer` rule returns `tar` artifacts, suitable to include in the `tars` attribute of the `oci_image` rule from rules_oci.

For an example using rules_docker rather than rules_oci, see the js_image_docker folder next to this one.

## Fine-grained layering

`js_image_layer` is a macro that yields two tar files `app.tar` and `node_modules.tar`. While `app.tar` contains first-party sources, `node_modules.tar` contains all third-party dependencies.

This speeds up developer change-build-push cycle by allowing build and push of only what has changed.

For instance, when a new third-party dependency is added, then only `node_modules.tar` will change and one will only have to push changes to dependencies.
On the other hand, if the application code is changed, then only `app.tar` will be updated and pushed.

## Selecting the right NodeJS interpreter

By default `js_binary` gets the nodejs interpreter for the host platform. However, this is not the case when including the js_binary in js_image_layer thanks to transitions. See [#3373](https://github.com/bazelbuild/rules_nodejs/pull/3373) for how this works.

Toolchain selection is controlled by `platform` attribute on `js_image_layer`.
NodeJS interpreter for a different platform can be obtained by changing `platform`.

Here is what the final image looks like when `platform = "linux/arm64"`:

```
app
|-- main
|-- main.runfiles
|   |-- __main__
|   |   |-- main.sh
|   |   |-- node_modules
|   |   |   `-- chalk -> /app/main.sh.runfiles/__main__/node_modules/.aspect_rules_js/chalk@4.1.2/node_modules/chalk
|   |   `-- src
|   |       |-- ascii.art
|   |       `-- main.js
|   |-- aspect_rules_js
|   |   `-- js
|   |       `-- private
|   |           `-- node-patches
|   |               |-- fs.cjs
|   |               `-- register.cjs
|   |-- bazel_tools
|   |   `-- tools
|   |       `-- bash
|   |           `-- runfiles
|   |               `-- runfiles.bash
|   `-- nodejs_linux_arm64
|       `-- bin
|           `-- nodejs
|               `-- bin
|                   `-- node
```
