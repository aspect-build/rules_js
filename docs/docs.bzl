"""
    Wrapper around stardoc_with_diff_test that only runs the test if Bazel 7 or greater is being used.
"""

load("@aspect_bazel_lib//lib:docs.bzl", _stardoc_with_diff_test = "stardoc_with_diff_test", _update_docs = "update_docs")
load("@aspect_bazel_lib//lib:utils.bzl", "is_bazel_7_or_greater")

def stardoc_with_diff_test(name, **kwargs):
    """
        Wrapper around stardoc_with_diff_test that only runs the test if Bazel 7 or greater is being used.
    """
    if is_bazel_7_or_greater():
        _stardoc_with_diff_test(name, **kwargs)
    else:
        # buildifier: disable=print
        print("WARNING: Skipping stardoc_with_diff_test for %s because it requires Bazel 7 or greater" % name)

update_docs = _update_docs
