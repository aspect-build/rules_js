"""Snapshot js_binary launchers into the source tree so they are shell checked on commit."""

load("@bazel_lib_host//:defs.bzl", "host")

def _collect_code_coverage_impl(_settings, _attr):
    return {"//command_line_option:collect_code_coverage": True}

_collect_code_coverage = transition(
    implementation = _collect_code_coverage_impl,
    inputs = [],
    outputs = ["//command_line_option:collect_code_coverage"],
)

def _launcher_with_coverage_impl(ctx):
    if len(ctx.attr.target) != 1:
        fail("target must be a single label")
    return DefaultInfo(files = depset([ctx.attr.target[0][DefaultInfo].files_to_run.executable]))

# The launcher only carries the lcov report generation logic when coverage is
# enabled, which is not the case for a plain `bazel build`.
launcher_with_coverage = rule(
    doc = "Forwards the launcher of `target` built with --collect_code_coverage.",
    implementation = _launcher_with_coverage_impl,
    attrs = {
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "target": attr.label(
            mandatory = True,
            cfg = _collect_code_coverage,
            executable = True,
        ),
    },
)

def launcher_snapshot(name, src):
    """Normalizes a launcher script for snapshotting.

    Args:
        name: Name of the genrule; the normalized script is `<name>.sh`.
        src: Label producing a single launcher script.
    """

    # Make sed replacements for consistency on different platform / Bazel version.
    # A configuration transition on the launcher appends an -ST-<hash> segment to
    # the output directory, which the first sed strips so $(BINDIR) still matches.
    # The trailing sed pipeline normalizes bzlmod canonical repo separators ~~/~
    # (Bazel 7) to ++/+ (Bazel 8+) so the snapshot matches across versions.
    native.genrule(
        name = name,
        srcs = [src],
        outs = [name + ".sh"],
        cmd = "cat $(execpath {src}) | sed -E \"s#(bazel-out/[^/]+)-ST-[^/]+/#\\\\1/#g\" | sed \"s#$(BINDIR)#bazel-out/k8-fastbuild/bin#\" | sed \"s#JS_BINARY__TARGET_CPU=\\\"$(TARGET_CPU)\\\"#JS_BINARY__TARGET_CPU=\\\"k8\\\"#\" | sed \"s#{platform}#linux_amd64#\" | sed \"s#\\\"{os}\\\"#\\\"k8\\\"#\" | sed -E -e 's/~~/++/g' -e 's|([+][+][^/~]+)~([^/~]+)~([^/~]+)|\\1+\\2+\\3|g' -e 's|([+][+][^/~]+)~([^/~]+)|\\1+\\2|g' > $@".format(
            src = src,
            platform = host.platform,
            os = host.os,
        ),
    )
