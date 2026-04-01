// Register source-map-support for source maps to be applied on stack traces.
require('source-map-support/register')

let basePath = process.env.JS_BINARY__RUNFILES
    ? `${process.env.JS_BINARY__RUNFILES}/${process.env.JS_BINARY__WORKSPACE}`
    : process.cwd()

if (!basePath.endsWith('/')) {
    basePath = basePath + '/'
}

/*
Before:
    Error: test
        at foo (/private/var/tmp/_bazel_username/67beefda950d56283b98d96980e6e332/execroot/aspect_rules_js/bazel-out/darwin_arm64-fastbuild/bin/examples/stack_traces/stack_trace_support.sh.runfiles/aspect_rules_js/examples/stack_traces/b.js:2:11)
        at Object.<anonymous> (/private/var/tmp/_bazel_username/67beefda950d56283b98d96980e6e332/execroot/aspect_rules_js/bazel-out/darwin_arm64-fastbuild/bin/examples/stack_traces/stack_trace_support.sh.runfiles/aspect_rules_js/examples/stack_traces/a.js:4:1)
        ...

After:
    Error: test
        at foo (examples/stack_traces/b.ts:2:9)
        at Object.<anonymous> (examples/stack_traces/a.ts:5:1)
        ...
*/

const basePathRegex = new RegExp(
    `(at | \\()${basePath
        .replace(/\\/g, '/')
        // Escape regex meta-characters.
        .replace(/[|\\{}()[\]^$+*?.]/g, '\\$&')
        .replace(/-/g, '\\x2d')}`,
    'g'
)

const prepareStackTrace = Error.prepareStackTrace
Error.prepareStackTrace = function (error, stack) {
    return prepareStackTrace(error, stack)
        .split('\n')
        .map((line) => line.replace(basePathRegex, '$1'))
        .join('\n')
}
