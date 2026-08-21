"""genjs_rule.bzl"""

JS_CONTENT = """
const data = require('./output.json');
console.log('hello', data.who + '!');
"""

JSON_CONTENT = '{"who": "world"}'

def _genjs_rule_impl(ctx):
    output_js = ctx.actions.declare_file(ctx.label.name + ".js")
    output_json = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(output_js, JS_CONTENT, is_executable = False)
    ctx.actions.write(output_json, JSON_CONTENT, is_executable = False)
    return DefaultInfo(
        files = depset([output_js, output_json]),
        runfiles = ctx.runfiles(files = [output_json]),
    )

genjs_rule = rule(
    implementation = _genjs_rule_impl,
)
