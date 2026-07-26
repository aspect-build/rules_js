"Helper rule for checking coverage"

load("//js/private:js_binary.bzl", "js_binary_lib")

# _lcov_merger must be a private attribute, so each merger needs its own rule.
def _coverage_test(merger, coverage_report = True):
    attrs = {
        "_lcov_merger": attr.label(
            executable = True,
            default = Label("//js/private/test/coverage:" + merger),
            cfg = "exec",
        ),
    }
    if coverage_report:
        # Generate + stash the report in the test action, the same as js_test.
        attrs["_coverage_report"] = attr.label(
            default = Label("//js/private/coverage:coverage.js"),
            allow_single_file = [".js"],
        )
    return rule(
        implementation = js_binary_lib.implementation,
        attrs = dict(js_binary_lib.attrs, **attrs),
        test = True,
        toolchains = js_binary_lib.toolchains,
    )

coverage_preexisting_test = _coverage_test("preexisting_merger")
coverage_pass_test = _coverage_test("pass_merger")
coverage_no_report_test = _coverage_test("no_report_merger", coverage_report = False)
