"Expose the generated splitter of a js_image_layer to tests"

_SplitterFilesInfo = provider(doc = "Generated splitter inputs", fields = ["files"])

def _splitter_files_aspect_impl(target, ctx):
    _ignore = ctx  # @unused
    for action in target.actions:
        if action.mnemonic == "JsImageLayerGroups":
            return [_SplitterFilesInfo(files = depset([
                f
                for f in action.inputs.to_list()
                if f.basename.endswith(("_js_image_layer_splitter.mjs", "_entries.json"))
            ]))]
    fail("{} has no JsImageLayerGroups action".format(target.label))

_splitter_files_aspect = aspect(implementation = _splitter_files_aspect_impl)

def _js_image_layer_splitter_impl(ctx):
    return [DefaultInfo(files = ctx.attr.js_image_layer[_SplitterFilesInfo].files)]

js_image_layer_splitter = rule(
    implementation = _js_image_layer_splitter_impl,
    doc = "The generated splitter script and the entries.json it reads.",
    attrs = {
        "js_image_layer": attr.label(mandatory = True, aspects = [_splitter_files_aspect]),
    },
)
