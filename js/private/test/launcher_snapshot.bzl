"""Writes a js_binary launcher to the source tree so that it is reviewed on every change.

Both launchers get the same treatment: bake one out, normalize the values that move
between platforms and Bazel versions, and check the result in. Sharing the normalization
matters because it is the fiddly part -- the sed expressions carry two layers of quoting
-- and because a value that has to be normalized in one launcher has to be normalized in
the other.
"""

load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_lib_host//:defs.bzl", "host")
load(":normalize.bzl", "REPO_SEPARATOR_NORMALIZE")

def launcher_snapshot(name, src, out, target_cpu_format, target_compatible_with):
    """Normalizes a generated launcher and writes it to the source tree.

    Args:
        name: name of the resulting write_source_files target.
        src: the generated launcher to snapshot.
        out: path of the checked-in snapshot, relative to this package.
        target_cpu_format: how the launcher spells the JS_BINARY__TARGET_CPU assignment,
            with `{}` where the cpu goes. One format rather than a search and a replacement
            so the two cannot describe different assignments.
        target_compatible_with: the launcher this snapshot exists for; see launcher_flags.bzl.
    """
    sed = "_{}_sed".format(name)
    native.genrule(
        name = sed,
        srcs = [src],
        outs = ["{}.normalized".format(sed)],
        cmd = " | ".join([
            "cat $(execpath {})".format(src),
            'sed "s#$(BINDIR)#bazel-out/k8-fastbuild/bin#"',
            'sed "s#{}#{}#"'.format(
                target_cpu_format.format("$(TARGET_CPU)"),
                target_cpu_format.format("k8"),
            ),
            'sed "s#{}#linux_amd64#"'.format(host.platform),
            'sed "s#\\"{}\\"#\\"k8\\"#"'.format(host.os),
            REPO_SEPARATOR_NORMALIZE,
        ]) + " > $@",
        target_compatible_with = target_compatible_with,
    )

    write_source_files(
        name = name,
        files = {out: sed},
    )
