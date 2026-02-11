"""Fork of 
https://github.com/protocolbuffers/protobuf/blob/95dc8a02ad7d64527f0850c17edb1b86d3996ad8/bazel/common/proto_common.bzl#L15
that exposes some helper functions that _compile uses, so we can implement our own version of it.
"""

load("@protobuf//bazel/common:proto_common.bzl", _proto_common = "proto_common")

def _import_virtual_proto_path(path):
    """Imports all paths for virtual imports.

      They're of the form:
      'bazel-out/k8-fastbuild/bin/external/foo/e/_virtual_imports/e' or
      'bazel-out/foo/k8-fastbuild/bin/e/_virtual_imports/e'"""
    if path.count("/") > 4:
        return "-I%s" % path
    return None

def _import_repo_proto_path(path):
    """Imports all paths for generated files in external repositories.

      They are of the form:
      'bazel-out/k8-fastbuild/bin/external/foo' or
      'bazel-out/foo/k8-fastbuild/bin'"""
    path_count = path.count("/")
    if path_count > 2 and path_count <= 4:
        return "-I%s" % path
    return None

def _import_main_output_proto_path(path):
    """Imports all paths for generated files or source files in external repositories.

      They're of the form:
      'bazel-out/k8-fastbuild/bin'
      'external/foo'
      '../foo'
    """
    if path.count("/") <= 2 and path != ".":
        return "-I%s" % path
    return None

def _output_directory(proto_info, root):
    proto_source_root = proto_info.proto_source_root
    if proto_source_root.startswith(root.path):
        #TODO: remove this branch when bin_dir is removed from proto_source_root
        proto_source_root = proto_source_root.removeprefix(root.path).removeprefix("/")

    if proto_source_root == "" or proto_source_root == ".":
        return root.path

    return root.path + "/" + proto_source_root

proto_common = struct(
    declare_generated_files = _proto_common.declare_generated_files,
    import_virtual_proto_path = _import_virtual_proto_path,
    import_repo_proto_path = _import_repo_proto_path,
    import_main_output_proto_path = _import_main_output_proto_path,
    output_directory = _output_directory,
)
