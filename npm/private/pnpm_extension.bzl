"""pnpm extension logic (the extension itself is in npm/extensions.bzl)."""

load("@aspect_bazel_lib//lib:lists.bzl", "unique")
load(":pnpm_repository.bzl", "DEFAULT_PNPM_VERSION", "LATEST_PNPM_VERSION")

DEFAULT_PNPM_REPO_NAME = "pnpm"

# copied from https://github.com/bazelbuild/bazel-skylib/blob/b459822483e05da514b539578f81eeb8a705d600/lib/versions.bzl#L60
# to avoid taking a dependency on skylib here
def _parse_version(version):
    return tuple([int(n) for n in version.split(".")])

def resolve_pnpm_repositories(mctx):
    """Resolves pnpm tags in all `modules`

    Args:
      mctx: module context

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

    for mod in mctx.modules:
        for attr in mod.tags.pnpm:
            if attr.name != DEFAULT_PNPM_REPO_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the pnpm repository.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if not registrations.get(attr.name, False):
                registrations[attr.name] = []

            if attr.pnpm_version_from and attr.pnpm_version and attr.pnpm_version != DEFAULT_PNPM_VERSION:
                fail("Cannot specify both pnpm_version = {} and pnpm_version_from = {}".format(attr.pnpm_version, attr.pnpm_version_from))

            # Handle pnpm_version_from by reading package.json
            if attr.pnpm_version_from != None:
                # Read package.json and extract packageManager field
                package_json_content = mctx.read(attr.pnpm_version_from)
                package_json = json.decode(package_json_content)

                if "packageManager" not in package_json:
                    fail("packageManager field not found in package.json file: " + str(attr.pnpm_version_from))

                package_manager = package_json["packageManager"]
                if not package_manager.startswith("pnpm@"):
                    fail("packageManager field must specify pnpm, got: " + package_manager)

                # Extract version from "pnpm@8.15.9" format
                v = package_manager[5:]  # Remove "pnpm@" prefix
                v = v.rsplit("+sha512.")[0]  # Remove optional "+sha512.<hash>" suffix

            elif attr.pnpm_version == "latest":
                v = LATEST_PNPM_VERSION
            else:
                v = attr.pnpm_version

            # Avoid inserting the default version from a non-root module
            # (likely rules_js itself) if the root module already has a version.
            if mod.is_root or len(registrations[attr.name]) == 0:
                registrations[attr.name].append(v)
            if attr.pnpm_version_integrity:
                integrity[attr.pnpm_version] = attr.pnpm_version_integrity
    for name, version_list in registrations.items():
        # Disregard repeated version numbers
        versions = unique(version_list)

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
