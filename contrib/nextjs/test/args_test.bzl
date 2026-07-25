"""Tests that the `args` of the Next.js build macros reach the `next` command line.

Each `nextjs_build` / `nextjs_standalone_build` target declares the `.next` output
directory of its own package, so each target under test must be in its own package,
alongside its own Next.js config file.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//contrib/nextjs:defs.bzl", "nextjs_build", "nextjs_standalone_build")

# The stand-in `next` binary shared by all test packages. The tests only inspect the
# generated actions, so `next` is never actually run.
_NEXT_JS_BINARY = "//contrib/nextjs/test:fake_next_binary"

def _args_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = [a for a in analysistest.target_actions(env) if a.mnemonic == "NextJs"]
    asserts.equals(env, 1, len(actions), "expected a single NextJs action")
    argv = actions[0].argv

    build_indexes = [i for i, arg in enumerate(argv) if arg == "build"]
    asserts.equals(env, 1, len(build_indexes), "expected a single `build` argument in {}".format(argv))

    # The `build` subcommand must come first, followed by `args` in the given order.
    asserts.equals(
        env,
        ["build"] + ctx.attr.expected_args,
        argv[build_indexes[0]:],
        "unexpected `next` arguments",
    )

    return analysistest.end(env)

_args_test = analysistest.make(
    _args_test_impl,
    attrs = {
        "expected_args": attr.string_list(
            doc = "The arguments expected after the `build` subcommand.",
        ),
    },
)

def nextjs_build_args_test(name, args = [], config = "next.config.mjs"):
    """Assert `nextjs_build(args)` is appended after the `build` subcommand.

    Args:
        name: Target name of the test target.
        args: The `args` to pass to `nextjs_build`.
        config: The Next.js config file, which must be in this package.
    """
    nextjs_build(
        name = "_{}.app".format(name),
        config = config,
        srcs = [],
        next_js_binary = _NEXT_JS_BINARY,
        args = args,
        tags = ["manual"],
    )

    _args_test(
        name = name,
        target_under_test = "_{}.app".format(name),
        expected_args = args,
    )

def nextjs_standalone_build_args_test(name, args = [], config = "next.standalone.mjs"):
    """Assert `nextjs_standalone_build(args)` is appended after the `build` subcommand.

    Args:
        name: Target name of the test target.
        args: The `args` to pass to `nextjs_standalone_build`.
        config: The Next.js config file, which must be in this package and must not be
            named `next.config.mjs`, which `nextjs_standalone_build` generates.
    """
    nextjs_standalone_build(
        name = "_{}.app".format(name),
        config = config,
        srcs = [],
        next_js_binary = _NEXT_JS_BINARY,
        args = args,
        tags = ["manual"],
    )

    _args_test(
        name = name,
        # The private `js_run_binary` running `next build` within `nextjs_standalone_build`.
        target_under_test = "__{}.app.next_build".format(name),
        expected_args = args,
    )
