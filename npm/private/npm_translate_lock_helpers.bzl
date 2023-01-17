"""Starlark helpers for npm_translate_lock."""

load("@bazel_skylib//lib:new_sets.bzl", "sets")

def _workspace_path(rctx, short_path, user_workspace_label):
    """Get the absolute path in the user repository of a short path using a reference label from the user repository."""
    label_path = rctx.path(user_workspace_label)
    label_short_path = user_workspace_label.package + ("/" if user_workspace_label.package else "") + user_workspace_label.name
    workspace_path = str(label_path).removesuffix(label_short_path)
    return rctx.path(workspace_path + "/" + short_path)

def _verify_patches(rctx):
    for ext in rctx.attr.verify_patches_extensions:
        if ext != "" and not ext.startswith("."):
            fail("ERROR: Invalid patch extension '{ext}' in `verify_patches_extensions`.".format(ext = ext))

    if rctx.attr.verify_patches and rctx.attr.patches != None:
        patches_folder_path = _workspace_path(rctx, rctx.attr.verify_patches, rctx.attr.pnpm_lock)

        files_in_patch_folder = patches_folder_path.readdir()
        all_patch_files = sets.make()
        for file in files_in_patch_folder:
            for ext in rctx.attr.verify_patches_extensions:
                if ext == "" and file.basename.find(".") == -1 or file.basename.endswith("." + ext):
                    sets.insert(all_patch_files, file)
                    break

        declared_patch_files = sets.make()

        for (_, pkg_patches) in rctx.attr.patches.items():
            for patch in pkg_patches:
                sets.insert(declared_patch_files, rctx.path(rctx.attr.pnpm_lock.relative(patch)))

        if not sets.is_subset(all_patch_files, declared_patch_files):
            missing_patches = sets.to_list(sets.difference(all_patch_files, declared_patch_files))
            missing_patches_formatted = "\n".join(["- %s" % path.basename for path in missing_patches])
            fail("""
ERROR: in verify_patches:

The following patches were found in {patches_folder} but were not listed
in the `patches` attribute of `npm_translate_lock`.

{missing_patches}

To disable this check, remove the `verify_patches` attribute from `npm_translate_lock`.

""".format(patches_folder = patches_folder_path, missing_patches = missing_patches_formatted))

helpers = struct(
    verify_patches = _verify_patches,
)
