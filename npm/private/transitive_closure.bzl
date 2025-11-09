"Helper utility for working with pnpm lockfile"

load(":utils.bzl", "utils")

def gather_transitive_closure(packages, package, cache = {}):
    """Walk the dependency tree, collecting the transitive closure of dependencies and their versions.

    This is needed to resolve npm dependency cycles.
    Note: Starlark expressly forbids recursion and infinite loops, so we need to iterate over a large range of numbers,
    where each iteration takes one item from the stack, and possibly adds many new items to the stack.

    Args:
        packages: dictionary from pnpm lock
        package: the package to collect deps for
        cache: a dictionary of results from previous invocations

    Returns:
        A dictionary of transitive dependencies, mapping package names to dependent versions.
    """
    root_package = packages[package]

    transitive_closure = {}
    transitive_closure[root_package["name"]] = [root_package["version"]]

    stack = [_get_package_info_deps(root_package)]
    iteration_max = 999999
    for i in range(0, iteration_max + 1):
        if not len(stack):
            break
        if i == iteration_max:
            msg = "gather_transitive_closure exhausted the iteration limit of {} - please report this issue".format(iteration_max)
            fail(msg)
        deps = stack.pop()
        for name in deps.keys():
            version = deps[name]
            if version.startswith("npm:"):
                # an aliased dependency
                package_key = version[4:]
                name, version = package_key.rsplit("@", 1)
            elif version not in packages:
                package_key = utils.package_key(name, version)
            else:
                package_key = version
            transitive_closure[name] = transitive_closure.get(name, [])
            if version in transitive_closure[name]:
                continue
            transitive_closure[name].append(version)
            if version.startswith("link:"):
                # we don't need to drill down through first-party links for the transitive closure since there are no cycles
                # allowed in first-party links
                continue

            if package_key in cache:
                # Already computed for this dep, merge the cached results
                for transitive_name in cache[package_key].keys():
                    transitive_closure[transitive_name] = transitive_closure.get(transitive_name, [])
                    for transitive_version in cache[package_key][transitive_name]:
                        if transitive_version not in transitive_closure[transitive_name]:
                            transitive_closure[transitive_name].append(transitive_version)
            elif package_key in packages:
                # Recurse into the next level of dependencies
                stack.append(_get_package_info_deps(packages[package_key]))
            else:
                msg = "Unknown package key: {} ({} @ {}) in {}".format(package_key, name, version, packages.keys())
                fail(msg)

    return utils.sorted_map(transitive_closure)

def _get_package_info_deps(package_info):
    return package_info["dependencies"] | package_info["optional_dependencies"]

def translate_to_transitive_closure(importers, packages):
    """Implementation detail of translate_package_lock, converts pnpm-lock to a different dictionary with more data.

    Args:
        importers: workspace projects (pnpm "importers")
        packages: all package info by name

    Returns:
        Nested dictionary suitable for further processing in our repository rule
    """

    # Collect deps of each importer (workspace projects)
    importers_deps = {}
    for lock_importer in importers.values():
        prod_deps = lock_importer["dependencies"]
        dev_deps = lock_importer["dev_dependencies"]
        opt_deps = lock_importer["optional_dependencies"]

        deps = prod_deps | opt_deps
        all_deps = prod_deps | dev_deps | opt_deps

        # TODO(3.0): remove this property
        # deps this importer should pass on if it is linked as a first-party package; this does
        # not include devDependencies
        lock_importer["deps"] = deps

        # TODO(3.0): remove this property
        # all deps of this importer to link in the node_modules folder of that Bazel package and
        # make available to all build targets; this includes devDependencies
        lock_importer["all_deps"] = all_deps

    # Collect transitive dependencies for each package
    cache = {}
    for package in packages.keys():
        transitive_closure = gather_transitive_closure(
            packages,
            package,
            cache,
        )

        packages[package]["transitive_closure"] = transitive_closure
        cache[package] = transitive_closure

    return (importers_deps, packages)
