"""
    Wrapper around stardoc_with_diff_test that only runs the test if Bazel 7 or greater is being used.
"""

load("@aspect_bazel_lib//lib:docs.bzl", _stardoc_with_diff_test = "stardoc_with_diff_test", _update_docs = "update_docs")

def stardoc_with_diff_test(name, **kwargs):
    """
        Wrapper around stardoc_with_diff_test that only runs the test if Bazel 7 or greater is being used.
    """
    _stardoc_with_diff_test(name, renderer = "//tools:stardoc_renderer", **kwargs)

update_docs = _update_docs
