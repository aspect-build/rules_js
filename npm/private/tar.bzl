"""Tar helpers."""

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")

# TODO: use a hermetic tar from aspect_bazel_lib and remove this.
def detect_system_tar(rctx):
    """Check if the host tar command is GNU tar.

    Args:
      rctx: the repository context
    Returns:
      True if the tar command is GNU tar, False otherwise
    """

    # We assume that any linux platform is using GNU tar.
    if repo_utils.is_linux(rctx):
        return "gnu"

    tar_args = ["tar", "--version"]
    result = rctx.execute(tar_args)
    if result.return_code:
        msg = "Failed to determine tar version. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(tar_args), result.return_code, result.stdout, result.stderr)
        fail(msg)

    return "gnu" if "GNU tar" in result.stdout else "non-gnu"
