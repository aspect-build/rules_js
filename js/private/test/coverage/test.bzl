"Helper rule for checking coverage"

load("//js/private:js_binary.bzl", "js_binary_lib")

coverage_fail_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = dict(js_binary_lib.attrs, **{
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/test/coverage:fail_merger"),
            cfg = "exec",
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
)

coverage_pass_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = dict(js_binary_lib.attrs, **{
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/test/coverage:pass_merger"),
            cfg = "exec",
        ),
        # Generate + stash the report in the test action, the same as js_test.
        "_coverage_report": attr.label(
            default = Label("//js/private/coverage:coverage.js"),
            allow_single_file = [".js"],
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
)

# Like coverage_pass_test but with a filename-agnostic "coverage is real" merger,
# for the expected_exit_code regression case (a passing test whose exit is
# non-zero).
coverage_expected_exit_test = rule(
    implementation = js_binary_lib.implementation,
    attrs = dict(js_binary_lib.attrs, **{
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/test/coverage:real_coverage_merger"),
            cfg = "exec",
        ),
        "_coverage_report": attr.label(
            default = Label("//js/private/coverage:coverage.js"),
            allow_single_file = [".js"],
        ),
    }),
    test = True,
    toolchains = js_binary_lib.toolchains,
)
