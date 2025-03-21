# Examples of using rules_js

This folder contains very small, self-contained examples.
We run the examples on CI as well, so they also serve as integration tests for this repo.

When reporting an issue, you can create a minimal reproduction by adding to this folder and send a PR (likely failing tests).
This helps us out since we can use your new example as the regression test.

Since rules_js users download this whole repo, our larger examples are in
<https://github.com/aspect-build/bazel-examples>. These include:

-   Angular 14: https://github.com/aspect-build/bazel-examples/tree/main/angular
-   Vue 3.x with Vite: https://github.com/aspect-build/bazel-examples/tree/main/vue

Examples in rules_ts

-   Protobuf and gRPC: https://github.com/aspect-build/rules_ts/tree/main/examples/proto_grpc
