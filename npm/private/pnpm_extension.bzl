"""pnpm extension logic (the extension itself is in npm/extensions.bzl)."""

load("@bazel_lib//lib:lists.bzl", "unique")
load(":pnpm_repository.bzl", "DEFAULT_PNPM_VERSION", "LATEST_PNPM_VERSION")
load(":utils.bzl", "utils")
load(":versions.bzl", "PNPM_VERSIONS")

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
      - `repositories`: dict (name -> {version, include_npm, integrity}) to invoke `pnpm_repository` with.
      - `notes`: list of notes to print to the user.
      - `facts`: Bazel module Facts to persist for future use (may be None).
    """

    # Collect all the module tags and associated versions/integrities/options
    integrity = {}
    registrations = {}
    for mod in mctx.modules:
        for attr in mod.tags.pnpm:
            if attr.name != DEFAULT_PNPM_REPO_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the pnpm repository.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if not registrations.get(attr.name, False):
                registrations[attr.name] = {}

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

                # Extract version and optional integrity from "pnpm@8.15.9+sha512.<hash>" format
                v = package_manager[5:]  # Remove "pnpm@" prefix
                if "+sha512." in v:
                    parts = v.rsplit("+sha512.", 1)
                    v = parts[0]

                    # Store the integrity hash. We need to convert the hex representation of the
                    # hash used by corepack, to the one Bazel understands: base64 encoded with a
                    # "sha512-" prefix.
                    integrity[v] = "sha512-" + utils.hex_to_base64(parts[1])

            elif attr.pnpm_version == "latest":
                v = LATEST_PNPM_VERSION
            else:
                v = attr.pnpm_version

            # Avoid inserting the default version from a non-root module
            # (likely rules_js itself) if the root module already has a version.
            if mod.is_root or len(registrations[attr.name]) == 0:
                if v not in registrations[attr.name]:
                    registrations[attr.name][v] = []
                registrations[attr.name][v].append(attr.include_npm)
            if attr.pnpm_version_integrity:
                integrity[attr.pnpm_version] = attr.pnpm_version_integrity

            # If no integrity was provided or found via package.json load from known versions
            if not integrity.get(v, False) and PNPM_VERSIONS.get(v, False):
                integrity[v] = PNPM_VERSIONS[v]

    # From the collected registrations, resolve to a single version per repository name
    notes = []
    repositories = {}
    for name, versions_map in registrations.items():
        # Disregard repeated version numbers and convert {version:include_npm} to version[]
        versions = unique(versions_map.keys())

        # Use "Minimal Version Selection" like bzlmod does for resolving module conflicts
        # Note, the 'sorted(list)' function in starlark doesn't allow us to provide a custom comparator
        if len(versions) > 1:
            selected = versions[0]
            selected_tuple = _parse_version(selected)
            for idx in range(1, len(versions)):
                if _parse_version(versions[idx]) > selected_tuple:
                    selected = versions[idx]
                    selected_tuple = _parse_version(selected)

            notes.append("NOTE: repo '{}' has multiple versions {}; selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        selected = {
            "version": selected,
            "include_npm": 0 < len([i for i in versions_map[selected] if i]),
            "integrity": integrity.get(selected, None),
        }

        repositories[name] = selected

    # If any repositories have no known integrity, try to fetch them from the npm registry and persist
    # them as Facts for future use.
    fetched_facts = None
    used_facts = None
    if hasattr(mctx, "facts") and len([v for v in repositories.values() if not v["integrity"]]) > 0:
        used_facts = {}
        for pnpm in repositories.values():
            if not pnpm["integrity"]:
                # Try fetching from any pre-existing facts first
                integrity = mctx.facts.get(pnpm["version"], None)
                if not integrity:
                    # Only fetch the list of pnpm versions once, and only if the version is not found in existing facts
                    if not fetched_facts:
                        fetched_facts = _fetch_pnpm_versions(mctx)
                    integrity = fetched_facts.get(pnpm["version"], None)

                if integrity:
                    pnpm["integrity"] = integrity
                    used_facts[pnpm["version"]] = integrity

    return struct(
        repositories = repositories,
        notes = notes,
        facts = used_facts,
    )

def _fetch_pnpm_versions(module_ctx):
    """Fetches pnpm versions and their integrity hashes from the npm registry.

    Returns:
        A dict mapping version strings to dicts with 'integrity' keys.
    """
    result = module_ctx.download(url = ["https://registry.npmjs.org/pnpm"], output = "pnpm_versions.json")
    if not result.success:
        # buildifier: disable=print
        print("ERROR: failed to fetch pnpm versions from npm registry: {}".format(result))
        return None

    data = module_ctx.read("pnpm_versions.json")

    # If the download failed such as being redirected to a custom registry page, the data may not be valid JSON
    # and can just be ignored with warning.
    if not data or data[0] != "{":
        # buildifier: disable=print
        print("ERROR: failed to read pnpm versions fetched from npm registry: {}".format(data))
        return None

    data = json.decode(data)
    versions = {}
    for version, info in data.get("versions", {}).items():
        if int(version.split(".")[0]) < 9:
            # Skip pnpm versions below 9
            continue

        dist = info.get("dist", {})
        integrity = dist.get("integrity", None)
        if integrity:
            versions[version] = integrity
    return versions
