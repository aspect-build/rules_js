# An example/e2e for rules_js + rules_docker

`js_image_layer.bzl` helper contains a macro to make rules_docker, pkg_tar and rules_js work together.

## Fine-grained layering

`js_image_layer` is a macro that yields two tar files `:<name>/app.tar` and `:<name>/node_modules.tar`. While `app.tar` contains first-party sources, `node_modules.tar` contains all third-party dependencies.

This speeds up developer change-build-push cycle by allowing build and push of only what has changed.

For instance, when a new third-party dependency is added, then only `node_modules.tar` will change and one will only have to push changes to dependencies.
On the other hand, if the application code is changed, then only `app.tar` will be updated and pushed.

To get more fine-grained layers, one could use [runfiles rule](./js_image_layer.bzl) from `js_image_layer.bzl` simply by changing `include` and `exclude` attributes.

Please see the [js_image_layer](./js_image_layer.bzl) for how this done for `app.tar` and `node_modules.tar`

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
