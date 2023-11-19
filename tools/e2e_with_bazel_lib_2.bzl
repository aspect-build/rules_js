"Macros for e2e testing across bazel-lib versions"

load("@aspect_bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_file")

BAZEL_LIB_2_COMPAT_VERSION = struct(
    version = "2.0.1",
    sha256 = "4b32cf6feab38b887941db022020eea5a49b848e11e3d6d4d18433594951717a",
)

def e2e_with_bazel_lib_2(name, src, workspace = True, module = True):
    """Copy an existing e2e substituting bazel-lib 2.x for bazel-lib 1.x.

    Args:
        name: Name of the write_source_files executable target to write the e2e to the source tree
        src: Workspace- elative path to the e2e, e.g., 'e2e/pnpm_workspace'
        workspace: Whether to substitute bazel-lib version in the WORKSPACE file. Defaults to True.
        module: Whether to substitute bazel-lib version in the MODULE.bazel file. Defaults to True.
    """

    modified_files = []
    if workspace:
        MODIFIED_WORKSPACE = "{}_WORKSPACE".format(name)
        WORKSPACE_CMDS = [
            "'set url \"https://github.com/aspect-build/bazel-lib/releases/download/v{version}/bazel-lib-v{version}.tar.gz\"'".format(version = BAZEL_LIB_2_COMPAT_VERSION.version),
            "'set strip_prefix \"bazel-lib-{}\"'".format(BAZEL_LIB_2_COMPAT_VERSION.version),
            "'set sha256 \"{}\"'".format(BAZEL_LIB_2_COMPAT_VERSION.sha256),
        ]

        native.genrule(
            name = "{}_WORKSPACE_subst".format(name),
            srcs = [src, "@buildifier_prebuilt//buildozer"],
            outs = [MODIFIED_WORKSPACE],
            cmd = "$(location @buildifier_prebuilt//buildozer) -stdout {} //$(location {})/WORKSPACE:aspect_bazel_lib > $@".format(" ".join(WORKSPACE_CMDS), src),
        )

        modified_files.append(MODIFIED_WORKSPACE)

    if module:
        MODIFIED_MODULE = "{}_MODULE.bazel".format(name)

        native.genrule(
            name = "{}_MODULE_subst".format(name),
            srcs = [src, "@buildifier_prebuilt//buildozer"],
            outs = [MODIFIED_MODULE],
            cmd = "$(location @buildifier_prebuilt//buildozer) -stdout 'set version {}' //$(location {})/MODULE.bazel:aspect_bazel_lib > $@".format(BAZEL_LIB_2_COMPAT_VERSION.version, src),
        )

        modified_files.append(MODIFIED_MODULE)

    # This copy will not work without `build --noexperimental_convenience_symlinks`
    # set in the e2e's bazelrc file it it was run locally. Adding a bazel-* exlcusion
    # pattern is not enough as bazel will detect symlink expansion and fail.
    copy_to_directory(
        name = "{}_copy".format(name),
        srcs = [src] + modified_files,
        out = "{}_copy".format(name),
        include_srcs_patterns = ["**"],
        exclude_srcs_patterns = ["{}/MODULE.bazel".format(src), "{}/WORKSPACE".format(src), "{}/.aspect".format(src)],
        replace_prefixes = {
            src: "",
            (name + "_"): "",
        },
        hardlink = "off",
    )

    write_source_file(
        name = name,
        in_file = ":{}_copy".format(name),
        out_file = "{}_bazel_lib_2".format(src),
        suggested_update_target = "//:update_e2es_with_bazel_lib_2",
    )
