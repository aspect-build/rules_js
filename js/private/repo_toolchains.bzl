"Helpers to locate toolchains from within repository rules"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")

def _ext(rctx, str_label):
    return ".exe" if repo_utils.is_windows(rctx) and not str_label.endswith(".exe") and not str_label.ends_with(".bat") and not str_label.endswith(".cmd") else ""

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
    return rctx.path(Label(str_label + _ext(rctx, str_label)))

def node_path(rctx):
    """Find the path to the host resolved node binary from a repository rule.

    Args:
        rctx: repository rule context containing a "node" label attr. If executing
            on windows and there is no .exe, .bat, or .cmd extension on the input label,
            then .exe will be automatically appended.

    Returns:
        Path to node
    """
    str_label = str(rctx.attr.node)
    return rctx.path(Label(str_label + _ext(rctx, str_label)))
