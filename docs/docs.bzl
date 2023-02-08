"Overrides for stardoc macros"

load("@aspect_bazel_lib//lib:docs.bzl", _stardoc_with_diff_test = "stardoc_with_diff_test", _update_docs = "update_docs")

def stardoc_with_diff_test(**kwargs):
    "Wrapper macro for stardoc_with_diff_test that skips the target when bzlmod is enabled."
    _stardoc_with_diff_test(
        # https://github.com/bazelbuild/stardoc/pull/141
        target_compatible_with = select({
            "//:bzlmod": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
        **kwargs
    )

def update_docs(**kwargs):
    "Wrapper macro for update_docs that skips the target when bzlmod is enabled."
    _update_docs(
        # https://github.com/bazelbuild/stardoc/pull/141
        target_compatible_with = select({
            "//:bzlmod": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
        **kwargs
    )
