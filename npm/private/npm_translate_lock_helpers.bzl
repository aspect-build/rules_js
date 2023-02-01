"""Starlark helpers for npm_translate_lock."""

load("@bazel_skylib//lib:new_sets.bzl", "sets")

def _verify_patches(rctx, state):
    if rctx.attr.verify_patches and rctx.attr.patches != None:
        rctx.report_progress("Verifying patches in {}".format(state.label_store.relative_path("verify_patches")))

        # Patches in the patch list verification file
        verify_patches_content = rctx.read(state.label_store.label("verify_patches")).strip(" \t\n\r")
        verify_patches = sets.make(verify_patches_content.split("\n"))

        # Patches in `patches` or `pnpm.patchedDependencies`
        declared_patches = sets.make([state.label_store.relative_path("patches_%d" % i) for i in range(state.num_patches())])

        if not sets.is_subset(verify_patches, declared_patches):
            missing_patches = sets.to_list(sets.difference(verify_patches, declared_patches))
            missing_patches_formatted = "\n".join(["- %s" % path for path in missing_patches])
            fail("""
ERROR: in verify_patches:

The following patches were found in {patches_list} but were not listed in the 
`patches` attribute of `npm_translate_lock` or in `pnpm.patchedDependencies`.

{missing_patches}

To disable this check, remove the `verify_patches` attribute from `npm_translate_lock`.

""".format(patches_list = state.label_store.relative_path("verify_patches"), missing_patches = missing_patches_formatted))

helpers = struct(
    verify_patches = _verify_patches,
)
