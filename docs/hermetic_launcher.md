# The hermetic launcher

A `js_binary` is normally invoked through a generated bash script
(`js/private/js_binary.sh.tpl`), which works out where node, the fs patches and
the entry point are, exports a set of `JS_BINARY__*` variables, changes into the
root of the output tree, and finally execs node. That is a shell process and a
few hundred lines of path resolution on every invocation, and it cannot run at
all where there is no bash.

The hermetic launcher is an experimental alternative, off by default. To enable it:

```sh
bazel build //... --@rules_js//js:use_hermetic_launcher
```

With the flag on, a `js_binary`'s executable is a small native binary stamped by
[hermetic_launcher](https://github.com/hermeticbuild/hermetic-launcher) which
does nothing but resolve its runfiles and `execve` node on a generated
JavaScript file, `<name>_/<name>.cjs`.
