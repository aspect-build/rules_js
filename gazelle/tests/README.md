# Gazelle TypeScript extension test cases

Each directory is a test case that contains `BUILD.in` and `BUILD.out` files for
assertion. `BUILD.in` is used as how the build file looks before running
Gazelle, and `BUILD.out` how the build file should look like after running
Gazelle.

Each test case is a Bazel workspace and Gazelle will run with its working
directory set to the root of this workspace.

See https://github.com/bazelbuild/bazel-gazelle/blob/master/extend.md#gazelle_generation_test-gazelle_binary