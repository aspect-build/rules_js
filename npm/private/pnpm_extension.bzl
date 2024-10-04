"""pnpm extension logic (the extension itself is in npm/extensions.bzl)."""

load(":pnpm_repository.bzl", "LATEST_PNPM_VERSION")

DEFAULT_PNPM_REPO_NAME = "pnpm"

# copied from https://github.com/bazelbuild/bazel-skylib/blob/b459822483e05da514b539578f81eeb8a705d600/lib/versions.bzl#L60
# to avoid taking a dependency on skylib here
def _parse_version(version):
    return tuple([int(n) for n in version.split(".")])

def resolve_pnpm_repositories(modules):
    """Resolves pnpm tags in all `modules`

    Args:
      modules: module_ctx.modules

    Returns:
      A struct with the following fields:
      - `repositories`: dict (name -> pnpm_version) to invoke `pnpm_repository` with.
      - `notes`: list of notes to print to the user.
    """

    registrations = {}
    integrity = {}

    result = struct(
        notes = [],
        repositories = {},
    )

    for mod in modules:
        for attr in mod.tags.pnpm:
            if attr.name != DEFAULT_PNPM_REPO_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the pnpm repository.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if attr.name not in registrations.keys():
                registrations[attr.name] = []

            v = attr.pnpm_version
            if v == "latest":
                v = LATEST_PNPM_VERSION

            registrations[attr.name].append(v)
            if attr.pnpm_version_integrity:
                integrity[attr.pnpm_version] = attr.pnpm_version_integrity
    for name, versions in registrations.items():
        # Use "Minimal Version Selection" like bzlmod does for resolving module conflicts
        # Note, the 'sorted(list)' function in starlark doesn't allow us to provide a custom comparator
        if len(versions) > 1:
            selected = versions[0]
            selected_tuple = _parse_version(selected)
            for idx in range(1, len(versions)):
                if _parse_version(versions[idx]) > selected_tuple:
                    selected = versions[idx]
                    selected_tuple = _parse_version(selected)

            result.notes.append("NOTE: repo '{}' has multiple versions {}; selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        result.repositories[name] = (selected, integrity[selected]) if selected in integrity.keys() else selected

    return result
