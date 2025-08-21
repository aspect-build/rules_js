"""Rules for running JavaScript programs"""

load("@aspect_tools_telemetry_report//:defs.bzl", "TELEMETRY")  # buildifier: disable=load
load(
    "//js/private:js_binary.bzl",
    _js_binary = "js_binary",
    _js_test = "js_test",
)
load(
    "//js/private:js_image_layer.bzl",
    _js_image_layer = "js_image_layer",
)
load(
    "//js/private:js_info_files.bzl",
    _js_info_files = "js_info_files",
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
    "//js/private:js_run_devserver.bzl",
    _js_run_devserver = "js_run_devserver",
)

# buildifier: disable=function-docstring
def js_binary(**kwargs):
    include_npm_sources = kwargs.pop("include_npm_sources", True)
    include_types = kwargs.pop("include_types", False)

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_npm_linked_packages = kwargs.pop("include_npm_linked_packages", None)
    if include_npm_linked_packages != None:
        # buildifier: disable=print
        print("""
WARNING: js_binary 'include_npm_linked_packages' is deprecated. Use 'include_npm_sources' instead.""")
        include_npm_sources = include_npm_linked_packages

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_declarations = kwargs.pop("include_declarations", False)
    if include_declarations:
        # buildifier: disable=print
        print("""
WARNING: js_binary 'include_declarations' is deprecated. Use 'include_types' instead.""")
        include_types = include_declarations

    _js_binary(
        include_npm_sources = include_npm_sources,
        include_types = include_types,
        enable_runfiles = select({
            Label("@aspect_bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

# buildifier: disable=function-docstring
def js_test(**kwargs):
    include_npm_sources = kwargs.pop("include_npm_sources", True)
    include_types = kwargs.pop("include_types", False)

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_npm_linked_packages = kwargs.pop("include_npm_linked_packages", None)
    if include_npm_linked_packages != None:
        # buildifier: disable=print
        print("""
WARNING: js_test 'include_npm_linked_packages' is deprecated. Use 'include_npm_sources' instead.""")
        include_npm_sources = include_npm_linked_packages

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_declarations = kwargs.pop("include_declarations", False)
    if include_declarations:
        # buildifier: disable=print
        print("""
WARNING: js_test 'include_declarations' is deprecated. Use 'include_types' instead.""")
        include_types = include_declarations

    _js_test(
        include_npm_sources = include_npm_sources,
        include_types = include_types,
        enable_runfiles = select({
            Label("@aspect_bazel_lib//lib:enable_runfiles"): True,
            "//conditions:default": False,
        }),
        **kwargs
    )

# buildifier: disable=function-docstring
def js_library(**kwargs):
    types = kwargs.pop("types", [])

    # For backward compat
    # TODO(3.0): remove backward compat handling
    declarations = kwargs.pop("declarations", None)
    if declarations:
        # buildifier: disable=print
        print("""
WARNING: js_library 'declarations' is deprecated. Use 'types' instead.""")
        types.extend(declarations)

    _js_library(
        types = types,
        **kwargs
    )

# buildifier: disable=function-docstring
def js_run_devserver(**kwargs):
    include_npm_sources = kwargs.pop("include_npm_sources", True)
    include_types = kwargs.pop("include_types", False)

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_npm_linked_packages = kwargs.pop("include_npm_linked_packages", None)
    if include_npm_linked_packages != None:
        # buildifier: disable=print
        print("""
WARNING: js_run_devserver 'include_npm_linked_packages' is deprecated. Use 'include_npm_sources' instead.""")
        include_npm_sources = include_npm_linked_packages

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_declarations = kwargs.pop("include_declarations", False)
    if include_declarations:
        # buildifier: disable=print
        print("""
WARNING: js_run_devserver 'include_declarations' is deprecated. Use 'include_types' instead.""")
        include_types = include_declarations

    _js_run_devserver(
        include_types = include_types,
        include_npm_sources = include_npm_sources,
        **kwargs
    )

# buildifier: disable=function-docstring
def js_run_binary(**kwargs):
    include_npm_sources = kwargs.pop("include_npm_sources", True)
    include_types = kwargs.pop("include_types", False)

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_npm_linked_packages = kwargs.pop("include_npm_linked_packages", None)
    if include_npm_linked_packages != None:
        # buildifier: disable=print
        print("""
WARNING: js_run_binary 'include_npm_linked_packages' is deprecated. Use 'include_npm_sources' instead.""")
        include_npm_sources = include_npm_linked_packages

    # For backward compat
    # TODO(3.0): remove backward compat handling
    include_declarations = kwargs.pop("include_declarations", False)
    if include_declarations:
        # buildifier: disable=print
        print("""
WARNING: js_run_binary 'include_declarations' is deprecated. Use 'include_types' instead.""")
        include_types = include_declarations

    _js_run_binary(
        include_types = include_types,
        include_npm_sources = include_npm_sources,
        **kwargs
    )

js_info_files = _js_info_files
js_image_layer = _js_image_layer
