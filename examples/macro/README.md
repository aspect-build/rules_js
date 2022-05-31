# macro example

This example shows how to create a wrapper macro around a generated `bin` entry from an npm package.

The macro is used to create `mocha_test` targets to test JavaScript with [mocha](https://mochajs.org/).
It also integrates with Bazel's JUnit XML consumer so that [`--test_summary=detailed`](https://bazel.build/docs/user-manual#test-summary) works.
