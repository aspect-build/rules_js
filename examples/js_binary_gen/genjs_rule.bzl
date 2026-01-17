"""genjs_rule.bzl"""

JS_CONTENT = """
console.log('hello world!')
"""

def _genjs_rule_impl(ctx):
    output_js = ctx.actions.declare_file(ctx.label.name + ".js")
    outputs = [output_js]
    ctx.actions.write(output_js, JS_CONTENT, is_executable = False)
    return DefaultInfo(files = depset(outputs))

genjs_rule = rule(
    implementation = _genjs_rule_impl,
)
