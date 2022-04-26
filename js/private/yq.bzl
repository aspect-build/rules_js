"Utilities for using the yq toolchain in a repository rule"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "is_windows_os")

def yq_bin(rctx, yq_repository):
    """Locate the path to a yq binary.

    Args:
        rctx: the repository context
        yq_repository: the name of the yq toolchain repository

    Returns:
        Path to the yq binary
    """

    # Parse the resolved host platform from yq host repo //:index.bzl
    content = rctx.read(rctx.path(Label("@%s_host//:index.bzl" % yq_repository)))
    search_str = "host_platform=\""
    start_index = content.index(search_str) + len(search_str)
    end_index = content.index("\"", start_index)
    host_platform = content[start_index:end_index]

    # Return the path to the yq binary
    return rctx.path(Label("@%s_%s//:yq%s" % (yq_repository, host_platform, ".exe" if is_windows_os(rctx) else "")))
