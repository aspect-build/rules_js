"contains container helper functions for js_binary"

load("@rules_pkg//:providers.bzl", "PackageFilegroupInfo", "PackageFilesInfo", "PackageSymlinkInfo")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

def _runfile_path(ctx, file, runfiles_dir):
    path = file.short_path
    if path.startswith(".."):
        return path.replace("..", runfiles_dir)
    if not file.owner.workspace_name:
        return "/".join([runfiles_dir, ctx.workspace_name, path])
    return path

_LAUNCHER_TMPL = """
export BAZEL_BINDIR=.
source {executable_path}
"""

def _write_laucher(ctx, executable_path):
    launcher = ctx.actions.declare_file("launcher.sh")

    ctx.actions.write(
        output = launcher,
        content = _LAUNCHER_TMPL.format(executable_path = executable_path),
        is_executable = True,
    )

    return launcher

def _runfiles_impl(ctx):
    default = ctx.attr.binary[DefaultInfo]

    executable = default.files_to_run.executable
    executable_path = "/".join([ctx.attr.root, executable.short_path])
    original_executable_path = executable_path.replace(".sh", "_.sh")
    launcher = _write_laucher(ctx, original_executable_path)

    files = depset(transitive = [default.files, default.default_runfiles.files])
    file_map = {
        original_executable_path: executable,
        executable_path: launcher,
    }

    manifest = default.files_to_run.runfiles_manifest
    runfiles_dir = "/".join([ctx.attr.root, manifest.short_path.replace(manifest.basename, "")[:-1]])

    for file in files.to_list():
        file_map[_runfile_path(ctx, file, runfiles_dir)] = file

    # executable and launcher should not go into runfiles directory so we add it to files here
    files = depset([executable, launcher], transitive = [files])

    symlinks = []

    # NOTE: pkg_tar is not capable of handling relative symlinks so they always have to be absolute
    # NOTE: symlinks is different than root_symlinks. See: https://bazel.build/rules/rules#runfiles_symlinks for distinction between root_symlinks and symlinks
    # and why they have to be handled differently.
    for symlink in default.data_runfiles.symlinks.to_list():
        destination = "/".join([runfiles_dir, ctx.workspace_name, symlink.path])
        if file_map[destination]:
            file_map.pop(destination)
        info = PackageSymlinkInfo(
            target = "/%s" % _runfile_path(ctx, symlink.target_file, runfiles_dir),
            destination = destination,
            attributes = {"mode": "0777"},
        )
        symlinks.append([info, symlink.target_file.owner])

    for symlink in default.data_runfiles.root_symlinks.to_list():
        destination = "/".join([runfiles_dir, symlink.path])
        if file_map[destination]:
            file_map.pop(destination)
        info = PackageSymlinkInfo(
            target = "/%s" % _runfile_path(ctx, symlink.target_file, runfiles_dir),
            destination = destination,
            attributes = {"mode": "0777"},
        )
        symlinks.append([info, symlink.target_file.owner])

    return [
        PackageFilegroupInfo(
            pkg_dirs = [],
            pkg_files = [
                [PackageFilesInfo(
                    dest_src_map = file_map,
                    attributes = {},
                ), ctx.label],
            ],
            pkg_symlinks = symlinks,
        ),
        DefaultInfo(files = files),
    ]

expand_runfiles = rule(
    implementation = _runfiles_impl,
    attrs = {
        "binary": attr.label(mandatory = True),
        "root": attr.string(),
    },
)

def js_image_layer(name, binary, root = None, **kwargs):
    """Creates a tar file containing runfiles from the binary

    Args:
        name: name for this target. Not reflected anywhere in the final tar.
        binary: label to js_image target
        root: Path where the js_binary will reside inside the final container image.
        **kwargs: Passed to pkg_tar. See: https://github.com/bazelbuild/rules_pkg/blob/main/docs/0.7.0/reference.md#pkg_tar
    """
    if root != None and not root.startswith("/"):
        fail("root path must start with '/' but got '{root}', expected '/{root}'".format(root = root))

    expand_runfiles(
        name = "%s.runfiles" % name,
        binary = binary,
        root = root,
    )

    if kwargs.pop("package_dir", None):
        fail("use 'root' attribute instead of 'package_dir'.")

    pkg_tar(
        name = name,
        # Be careful with this option. Leave it as is if you don't know what you are doing
        strip_prefix = kwargs.pop("strip_prefix", "."),
        srcs = ["%s.runfiles" % name],
        **kwargs
    )
