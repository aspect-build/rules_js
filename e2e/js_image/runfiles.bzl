"contains container helper functions for js_binary"

load("@rules_pkg//:providers.bzl", "PackageFilegroupInfo", "PackageFilesInfo", "PackageSymlinkInfo")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:defs.bzl", "py_binary")

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
        if hasattr(file_map, "build_tar"):
            file_map.pop(destination)
        info = PackageSymlinkInfo(
            target = "/%s" % _runfile_path(ctx, symlink.target_file, runfiles_dir),
            destination = destination,
            attributes = {"mode": "0777"},
        )
        symlinks.append([info, symlink.target_file.owner])

    for symlink in default.data_runfiles.root_symlinks.to_list():
        destination = "/".join([runfiles_dir, symlink.path])
        if hasattr(file_map, "build_tar"):
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

BUILD_TAR = """
import os
import sys
import json
import subprocess
from rules_python.python.runfiles import runfiles

r = runfiles.Create()
build_tar_path = r.Rlocation("rules_pkg/pkg/private/tar/build_tar")

manifest_path = next((argv.replace("--manifest=", "") for argv in sys.argv if argv.startswith("--manifest=")), None)

with open(manifest_path, 'r') as manifest_fp:
    manifest = json.load(manifest_fp)

def strip_execroot(p):
    parts = p.split(os.sep)
    i = parts.index("execroot") 
    return os.sep.join(parts[i+2:]) 

def get_runfiles_path(p):
    for entry in manifest:
        if entry[2] == p:
            return entry[1]
    raise Exception("could not find a corresponding file for %s within manifest.")


for entry in manifest:
    p = entry[2]
    if "node_modules" in p and os.path.islink(p):
        link_to = os.path.realpath(p)
        link_to_execroot_stripped = strip_execroot(link_to)
        overwritten_to = get_runfiles_path(link_to_execroot_stripped)
        # fix it!
        entry[0] = 1 # make it a symlink
        entry[2] = "/%s" % overwritten_to
        entry[3] = "0777"

os.remove(manifest_path)
with open(manifest_path, "w") as manifest_w:
    manifest_w.write(json.dumps(manifest))

print(os.path.realpath(build_tar_path))

r = subprocess.run([build_tar_path] + sys.argv[1:])
sys.exit(r.returncode)
"""

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

    if kwargs.pop("package_dir", None):
        fail("use 'root' attribute instead of 'package_dir'.")

    entrypoint_name = "%s_build_tar_entrypoint.py" % name
    write_file(
        name = "%s.build_tar_entrypoint" % name,
        out = entrypoint_name,
        content = [BUILD_TAR],
        tags = ["manual"],
    )

    py_binary(
        name = "%s.build_tar" % name,
        srcs = [entrypoint_name],
        main = entrypoint_name,
        deps = ["@rules_python//python/runfiles"],
        data = [
            "@rules_pkg//pkg/private/tar:build_tar",
        ],
        tags = ["manual"],
    )

    expand_runfiles(
        name = "%s.runfiles" % name,
        binary = binary,
        root = root,
    )

    pkg_tar(
        name = name,
        # Be careful with this option. Leave it as is if you don't know what you are doing
        strip_prefix = kwargs.pop("strip_prefix", "."),
        srcs = ["%s.runfiles" % name],
        build_tar = "%s.build_tar" % name,
        **kwargs
    )
