# Protobuf examples

This directory contains examples of how to set up and use several different
JavaScript and TypeScript protobuf implementations.

Note that we jump through some extra hoops here to make it possible to have
multiple JS protobuf implementations in the same Bazel repo. We do this by
setting `target_settings = [...]` on each `js_proto_toolchain()` and then
relying on a config transition in `js_proto_transition_library()` to select the
toolchain to use. Unless you have an unusual situation, you do not need to
worry about this. Just define a single `js_proto_toolchain()` (without
`target_settings`), register it in your `MODULE.bazel` file, and then you are
good to go.
