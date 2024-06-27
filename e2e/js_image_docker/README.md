# An example for rules_js + rules_docker

The `js_image_layer` rule returns `tar` artifacts, suitable to include in the `tars` attribute of the `container_image` rule from rules_docker.
You can `bazel run` the target to get the image to load into your Docker daemon.
See the [rules_docker documentation](https://github.com/bazelbuild/rules_docker/blob/a8aff4076f75c4dfb39bd768dd9870b5d263e70d/README.md#using-with-docker-locally)

> Like all lang_image rules in rules_docker, the nodejs_image rule has different behavior under `bazel run` where the container is booted and executes.

For an example using rules_oci rather than rules_docker, see the js_image_oci folder next to this one.

## Fine-grained layering

`js_image_layer` is a macro that yields two tar files `app.tar` and `node_modules.tar`. While `app.tar` contains first-party sources, `node_modules.tar` contains all third-party dependencies.

This speeds up developer change-build-push cycle by allowing build and push of only what has changed.

For instance, when a new third-party dependency is added, then only `node_modules.tar` will change and one will only have to push changes to dependencies.
On the other hand, if the application code is changed, then only `app.tar` will be updated and pushed.

### dive <image>

```
│ Layers ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cmp   Size  Command
    118 MB  FROM 27d8bf01e7ea3c5
     78 MB  bazel build ...
     97 kB  bazel build ...
       0 B  #(nop) ADD file:64c455af1bb18ff2c202a244e058b6e5ac147b89410ed36edc5e29f4b6f02c5d in /

│ Image Details ├───────────────────────────────────────────────────────────────────────────────────────────

Image name: localhost/bazel:image
Total Image size: 196 MB
Potential wasted space: 0 B
Image efficiency score: 100 %
```

As seen in the [dive](https://github.com/wagoodman/dive) output the largest layer is our base image which is `118 MB` followed by `78 MB` which is the dependencies and finally `97 kB` which is the app itself.
Additionally, we get a `100%` efficiency score which means there are no duplicate or `whiteout` files to waste space.

## Selecting the right NodeJS interpreter

By default `js_binary` gets the nodejs interpreter for the host platform. However, this is not the case when including the js_binary in container_image thanks to transitions. See [#3373](https://github.com/bazelbuild/rules_nodejs/pull/3373) and [#1963](https://github.com/bazelbuild/rules_docker/pull/1963) for how this works.

Toolchain selection is controlled by `operating_system` and `architecture` attribute on `container_image` which is `linux/amd64` by default.

NodeJS interpreter for a different platform can be obtained by changing `operating_system` and `architecture`.

Here is what the final image looks like when the platform is `linux/arm64`

```
app
|-- main.sh
|-- main.sh.runfiles
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
`-- main_.sh

17 directories, 9 files
```
