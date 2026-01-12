"""In order to avoid late restarts, repository rules should pre-compute dynamic labels and
paths to static & dynamic labels. This helper "class" abstracts that into a tidy interface.

See https://github.com/bazelbuild/bazel-gazelle/issues/1175 &&
https://github.com/bazelbuild/rules_nodejs/issues/2620 for more context. A fix in Bazel may
resolve the underlying issue in the future https://github.com/bazelbuild/bazel/issues/16162.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

################################################################################
def _add(priv, rctx_path, repo_root, key, label):
    priv["labels"][key] = label
    priv["paths"][key] = str(rctx_path(label))
    priv["repository_paths"][key] = paths.join(repo_root, label.package, label.name)
    priv["relative_paths"][key] = paths.join(label.package, label.name)

################################################################################
def _has(priv, key):
    return key in priv["labels"]

################################################################################
def _label(priv, key):
    return priv["labels"][key]

################################################################################
def _path(priv, key):
    return priv["paths"][key]

################################################################################
def _repository_path(priv, key):
    return priv["repository_paths"][key]

################################################################################
def _relative_path(priv, key):
    return priv["relative_paths"][key]

################################################################################
def _new(rctx_path):
    priv = {
        "root": None,
        "labels": {},
        "paths": {},
        "repository_paths": {},
        "relative_paths": {},
    }

    repo_root = str(rctx_path(""))

    return struct(
        repo_root = repo_root,
        add = lambda key, label: _add(priv, rctx_path, repo_root, key, label),
        has = lambda key: _has(priv, key),
        label = lambda key: _label(priv, key),
        path = lambda key: _path(priv, key),
        repository_path = lambda key: _repository_path(priv, key),
        relative_path = lambda key: _relative_path(priv, key),
    )

repository_label_store = struct(
    new = _new,
)
