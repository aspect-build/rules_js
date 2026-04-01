"""Macros wrapping the less compiler from the other_module npm packages."""

load("@npm_other_module//:less/package_json.bzl", less_bin = "bin")

def lessc(name, css, **kwargs):
    """Compile a .less file to .css using the less compiler from other_module."""
    less_bin.lessc(
        name = name,
        srcs = [css],
        outs = [css.replace(".less", ".css")],
        args = [
            css,
            css.replace(".less", ".css"),
        ],
        chdir = kwargs.pop("chdir", "."),
        **kwargs
    )

def lessc_binary(name, **kwargs):
    """Create a standalone lessc binary from the less compiler in other_module."""
    less_bin.lessc_binary(
        name = name,
        **kwargs
    )
