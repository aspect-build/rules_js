"Example macro for generating multiple npm_translate_lock repositories"

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")

def npm_repository_name(pnpm_workspace):
    return "npm" if not pnpm_workspace else "npm_{}".format(pnpm_workspace.replace("/", "_"))

def npm_translate_locks(pnpm_workspaces):
    for pnpm_workspace in pnpm_workspaces:
        npm_translate_lock(
            name = npm_repository_name(pnpm_workspace),
            pnpm_lock = "//{}:pnpm-lock.yaml".format(pnpm_workspace),
            verify_node_modules_ignored = "//:.bazelignore",
        )
