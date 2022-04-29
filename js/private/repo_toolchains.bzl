"Helpers to locate toolchains from within repository rules"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")

def yq_path(rctx):
    """Find the path to the host resolved yq binary from a repository rule.

    Args:
        rctx: Repository rule context containing a "yq" label attr. If executing
            on windows and there is no .exe, .bat, or .cmd extension on the input label,
            then .exe will be automatically appended.

    Returns:
        Path to yq.
    """
    str_label = str(rctx.attr.yq)
    ext = ".exe" if repo_utils.is_windows(rctx) and not str_label.endswith(".exe") and not str_label.ends_with(".bat") and not str_label.endswith(".cmd") else ""
    return rctx.path(Label(str_label + ext))

def node_path(rctx):
    """Find the path to the host resolved node binary from a repository rule.

    Args:
        rctx: repository rule context containing a "node_repository" string attr.

    Returns:
        Path to node
    """

    # Parse the resolved host platform from node host repo //:index.bzl
    content = rctx.read(rctx.path(Label("@%s_host//:index.bzl" % rctx.attr.node_repository)))
    search_str = "host_platform=\""
    start_index = content.index(search_str) + len(search_str)
    end_index = content.index("\"", start_index)
    host_platform = content[start_index:end_index]

    # Return the path to the node binary
    return rctx.path(Label("@%s_%s//:bin/node%s" % (rctx.attr.node_repository, host_platform, ".exe" if repo_utils.is_windows(rctx) else "")))
