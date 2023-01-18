"""Starlark helpers for npm_translate_lock."""

load("@bazel_skylib//lib:new_sets.bzl", "sets")

def _verify_patches(rctx, label_store):
    if rctx.attr.verify_patches and rctx.attr.patches != None:
        rctx.report_progress("Verifying patches in {}".format(label_store.relative_path("verify_patches")))

        # Patches in the patch list verification file
        verify_patches_content = rctx.read(label_store.label("verify_patches")).strip(" \t\n\r")
        verify_patches = sets.make(verify_patches_content.split("\n"))

        # Patches declared in the `patches` attr
        declared_patch_count = 0
        for pkg_patches in rctx.attr.patches.values():
            declared_patch_count += len(pkg_patches)
        declared_patches = sets.make([label_store.relative_path("patches_%d" % i) for i in range(declared_patch_count)])

        if not sets.is_subset(verify_patches, declared_patches):
            missing_patches = sets.to_list(sets.difference(verify_patches, declared_patches))
            missing_patches_formatted = "\n".join(["- %s" % path for path in missing_patches])
            fail("""
ERROR: in verify_patches:

The following patches were found in {patches_list} but were not listed
in the `patches` attribute of `npm_translate_lock`.

{missing_patches}

To disable this check, remove the `verify_patches` attribute from `npm_translate_lock`.

""".format(patches_list = label_store.relative_path("verify_patches"), missing_patches = missing_patches_formatted))

helpers = struct(
    verify_patches = _verify_patches,
)
