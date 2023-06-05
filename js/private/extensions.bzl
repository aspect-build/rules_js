"""Adapt js repository rules to be called from MODULE.bazel
See https://bazel.build/docs/bzlmod#extension-definition
"""

load("//js/private:repository_utils.bzl", "config_settings")

def _js_impl(_module_ctx):
    config_settings(name = "aspect_rules_js_config_settings")

js = module_extension(
    implementation = _js_impl,
)
