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

def _compile(
        actions,
        proto_lang_toolchain_info,
        protoc_info,
        generated_files,
        proto_info,
        mnemonic,
        progress_message,
        host_path_separator,
        additional_args = None):
    """Run a protoc action using descriptor sets as inputs.

    This is a vendored variant of proto_common.compile (from the protobuf repo)
    that uses --descriptor_set_in rather than transitive_sources, and sets
    BAZEL_BINDIR so that protoc plugins implemented as Node.js binaries can
    locate their runfiles.

    Args:
        actions: (ActionFactory) Obtained by ctx.actions.
        proto_lang_toolchain_info: (ProtoLangToolchainInfo) The proto lang toolchain.
        protoc_info: The proto compiler info, from ctx.toolchains[PROTOC_TOOLCHAIN].proto.
        generated_files: (list[File]) The declared output files for the action.
        proto_info: (ProtoInfo) The ProtoInfo from the proto_library dependency.
        mnemonic: (str) The mnemonic for the action.
        progress_message: (str) The progress message for the action.
        host_path_separator: (str) Path separator for the host platform (ctx.configuration.host_path_separator).
        additional_args: (list[str]) Optional extra arguments inserted before the source files.
    """
    proto_outdir = _output_directory(proto_info, generated_files[0].root)
    descriptor_sets = proto_info.transitive_descriptor_sets
    direct_sources = proto_info.direct_sources

    args = actions.args()
    args.add(proto_lang_toolchain_info.plugin.executable, format = proto_lang_toolchain_info.plugin_format_flag)
    args.add_all((proto_lang_toolchain_info.out_replacement_format_flag % proto_outdir).split(" "))
    args.add("--descriptor_set_in")
    args.add_joined(descriptor_sets, join_with = host_path_separator)

    # Protoc searches for .protos -I paths in order they are given and then
    # uses the path within the directory as the package.
    # This requires ordering the paths from most specific (longest) to least
    # specific ones, so that no path in the list is a prefix of any of the
    # following paths in the list.
    # For example: 'bazel-out/k8-fastbuild/bin/external/foo' needs to be listed
    # before 'bazel-out/k8-fastbuild/bin'. If not, protoc will discover the file
    # under the shorter path and use 'external/foo/...' as its package path.
    args.add_all(proto_info.transitive_proto_path, map_each = _import_virtual_proto_path)
    args.add_all(proto_info.transitive_proto_path, map_each = _import_repo_proto_path)
    args.add_all(proto_info.transitive_proto_path, map_each = _import_main_output_proto_path)
    args.add("-I.")  # Needs to come last

    if additional_args:
        args.add_all(additional_args)

    args.add_all(direct_sources)

    output_root = generated_files[0].root
    actions.run(
        executable = protoc_info.proto_compiler.executable,
        arguments = [args],
        progress_message = progress_message,
        mnemonic = mnemonic,
        env = {"BAZEL_BINDIR": output_root.path},
        tools = [proto_lang_toolchain_info.plugin, protoc_info.proto_compiler],
        inputs = depset(direct_sources, transitive = [descriptor_sets]),
        outputs = generated_files,
        use_default_shell_env = True,
    )

proto_common = struct(
    compile = _compile,
    declare_generated_files = _proto_common.declare_generated_files,
    import_virtual_proto_path = _import_virtual_proto_path,
    import_repo_proto_path = _import_repo_proto_path,
    import_main_output_proto_path = _import_main_output_proto_path,
    output_directory = _output_directory,
)
