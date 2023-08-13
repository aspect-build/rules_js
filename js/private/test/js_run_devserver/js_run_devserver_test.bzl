load("//js/private:js_run_devserver.bzl", "js_run_devserver", "js_run_devserver_lib")

_js_run_devserver_test = rule(
    attrs = js_run_devserver_lib.attrs,
    implementation = js_run_devserver_lib.implementation,
    toolchains = js_run_devserver_lib.toolchains,
    test = True,
)

# 'test' version of js_run_devserver
def js_run_devserver_test(
        name,
        tags = [],
        **kwargs):

    js_run_devserver(
        name,
        js_run_devserver_rule = _js_run_devserver_test,
        # 'no-sandbox' needed to simulate 'bazel run' command - normally tests 
        # are sandboxed, and sandboxing doesn't exhibit the issue in 
        # https://github.com/aspect-build/rules_js/issues/1204
        tags = tags + ['no-sandbox'], 
        **kwargs,
    )
