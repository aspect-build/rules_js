# An example/e2e for rules_js + rules_docker

`js_image_layer.bzl` helper contains some logic to make rules_docker, pkg_tar and rules_js work together.

## Fine-grained layering

`js_image_layer` is a macro that yields two tar files `:<name>/app.tar` and `:<name>/node_modules.tar` which helps to speed things up by splitting files into two layers. While `app.tar` contains your code, `node_modules.tar` contains your third-party dependencies.

More specifically, when one adds a new dependency, then only `node_modules.tar` will change and one will only have to push changes to dependencies.
On the other hand, if one changes the application code, then only `app.tar` will change.

To get more fine-grained layers one could use `runfiles` rule from `js_image_layer.bzl` simply by changing `include` and `exclude` attributes.

Please see the `js_image_layer` macro for an example.

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

As seen in the `dive` output the largest layer is our base image which is `118 MB` followed by `78 MB` which is the dependencies and finally `97 kB` which is the app itself.
Additionally, we get a `100%` efficiency score which means there are no duplicate or `whiteout` files to waste space.
