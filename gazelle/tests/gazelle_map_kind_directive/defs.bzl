load("@npm//@bazel/typescript:index.bzl", "ts_project")

def ts_my_project(name, **kwargs) {
    ts_project(name, **kwargs)
}