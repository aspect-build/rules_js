"""Rules for running JavaScript programs"""

load(
    "//js/private:js_binary.bzl",
    _js_binary = "js_binary",
    _js_test = "js_test",
)
load(
    "//js/private:js_library.bzl",
    _js_library = "js_library",
)
load(
    "//js/private:js_run_binary.bzl",
    _js_run_binary = "js_run_binary",
)
load(
    "//js/private:js_info_files.bzl",
    _js_info_files = "js_info_files",
)
load(
    "//js/private:js_run_devserver.bzl",
    _js_run_devserver = "js_run_devserver",
)
load(
    "//js/private:js_image_layer.bzl",
    _js_image_layer = "js_image_layer",
)

# buildifier: disable=function-docstring
def js_binary(**kwargs):
    include_npm_deps = kwargs.pop("include_npm_deps", False)

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_npm_linked_packages = kwargs.pop("include_npm_linked_packages", None)
    if include_npm_linked_packages != None:
        # buildifier: disable=print
        print("""
WARNING: js_library 'include_npm_linked_packages' is deprecated. Use 'include_npm_deps' instead.""")
        include_npm_deps = include_npm_linked_packages

    _js_binary(
        include_npm_deps = include_npm_deps,
        enable_runfiles = select({
            Label("@aspect_bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

# buildifier: disable=function-docstring
def js_test(**kwargs):
    _js_test(
        enable_runfiles = select({
            Label("@aspect_bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

js_run_devserver = _js_run_devserver
js_info_files = _js_info_files
js_library = _js_library
js_run_binary = _js_run_binary
js_image_layer = _js_image_layer
