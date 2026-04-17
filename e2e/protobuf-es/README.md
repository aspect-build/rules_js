# Buf.build protobuf-es example

This directory contains an example of how to set up and use the Buf.build
protobuf-es implementation, along with Connect and Connect-Query. See also
e2e/protobuf-google/ for an example of how to use Google's protobuf
implementation.

Ideally we would like to support every JavaScript or TypeScript implementation
for which Buf [provides](https://buf.build/bazel/bazel/sdks/main:protobuf) an
SDK, but we do not currently support pure-TypeScript implementations such as
[ts-proto](https://github.com/stephenh/ts-proto). Such implementations would
require some additional work to support, because `js_proto_aspect()` produces a
`JsInfo` provider, which cannot contain pure TypeScript files. If and when we
add support for pure TypeScript, it will likely look something like this:

-   Depending on whether or not the protobuf implementation uses pure
    TypeScript, `js_proto_aspect()` will output either a `JsInfo` or a new
    provider named `TsInfo` or similar. `TsInfo` will contain unprocessed `.ts`
    files.
-   The
    [ts_proto_library()](https://github.com/aspect-build/rules_ts/blob/d4dde5758fb2aa9003692f813357ce0624a95329/ts/proto.bzl#L49)
    rule will invoke `js_proto_aspect()` to generate the `TsInfo` providers and
    then run `tsc` or another TypeScript transpiler.

Note: the [protobuf-ts](https://github.com/timostamm/protobuf-ts)
implementation is a pure-TypeScript implementation, but it can be made to
produce `.js` and `.d.ts` files using its `output_javascript` option. However,
it is unfortunately still not supported yet due to [issue
#656](https://github.com/timostamm/protobuf-ts/issues/656).
