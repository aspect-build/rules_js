"Make shorter assertions"

load("@aspect_bazel_lib//lib:utils.bzl", "is_bzlmod_enabled")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file", "write_source_files")
load("//js:defs.bzl", "js_image_layer")

# buildifier: disable=function-docstring
def assert_tar_listing(name, actual, expected):
    actual_listing = "_{}_listing".format(name)
    native.genrule(
        name = actual_listing,
        srcs = [actual],
        testonly = True,
        outs = ["_{}.listing".format(name)],
        cmd = 'TZ="UTC" LC_ALL="en_US.UTF-8" $(BSDTAR_BIN) -tvf $(execpath {}) >$@'.format(actual),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    write_source_file(
        name = name,
        in_file = actual_listing,
        out_file = expected,
        testonly = True,
    )

layers = [
    "node",
    "package_store_1p",
    "package_store_3p",
    "node_modules",
    "app",
]

# buildifier: disable=function-docstring
def assert_js_image_layer_listings(name, js_image_layer):
    for layer in layers:
        assert_tar_listing(
            name = "assert_{}_{}".format(name, layer),
            actual = "{}_{}".format(js_image_layer, layer),
            expected = "{}_{}{}.listing".format(name, layer, (".bzlmod" if is_bzlmod_enabled() else ".nobzlmod")),
        )

    write_source_files(
        name = name + "_update_all",
        additional_update_targets = [
            "assert_{}_{}".format(name, layer)
            for layer in layers
        ],
        testonly = True,
    )

# buildifier: disable=function-docstring
def make_js_image_layer(name, **kwargs):
    js_image_layer(
        name = name,
        testonly = 1,
        tags = [
            # mode bit on files aren't stable between RBE and Local since RBE isn't aware of git which tracks permissions for files.
            # we don't care about unstable inputs because it's not our responsibility to keep them stable which would expand api surface for js_image_layer
            "no-remote-exec",
        ],
        **kwargs
    )

    for layer in layers:
        native.filegroup(
            name = name + "_" + layer,
            srcs = [name],
            output_group = layer,
            testonly = 1,
        )

def assert_checksum(name, image_layer):
    native.genrule(
        name = name,
        testonly = True,
        srcs = [image_layer],
        outs = [name + ".checksums"],
        cmd = """
COREUTILS_BIN=$$(realpath $(COREUTILS_BIN)) &&
RESULT="$$($$COREUTILS_BIN sha256sum $(SRCS))"
BINDIR="$(BINDIR)/"
echo "$${RESULT//$$BINDIR/}" > $@
    """,
        output_to_bindir = True,
        toolchains = ["@coreutils_toolchains//:resolved_toolchain"],
    )

    write_source_file(
        name = name + "_test",
        testonly = True,
        in_file = name,
        out_file = name + ("." if is_bzlmod_enabled() else ".no") + "bzlmod.expected",
    )
