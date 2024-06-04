"Helper utility for working with pnpm lockfile"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":utils.bzl", "utils")

def gather_transitive_closure(packages, package, no_optional, cache = {}):
    """Walk the dependency tree, collecting the transitive closure of dependencies and their versions.

    This is needed to resolve npm dependency cycles.
    Note: Starlark expressly forbids recursion and infinite loops, so we need to iterate over a large range of numbers,
    where each iteration takes one item from the stack, and possibly adds many new items to the stack.

    Args:
        packages: dictionary from pnpm lock
        package: the package to collect deps for
        no_optional: whether to exclude optionalDependencies
        cache: a dictionary of results from previous invocations

    Returns:
        A dictionary of transitive dependencies, mapping package names to dependent versions.
    """
    root_package = packages[package]

    transitive_closure = {}
    transitive_closure[root_package["name"]] = [root_package["version"]]

    stack = [_get_package_info_deps(root_package, no_optional)]
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
                stack.append(_get_package_info_deps(packages[package_key], no_optional))
            else:
                msg = "Unknown package key: {} ({} @ {}) in {}".format(package_key, name, version, packages.keys())
                fail(msg)

    return utils.sorted_map(transitive_closure)

def _get_package_info_deps(package_info, no_optional):
    return package_info["dependencies"] if no_optional else dicts.add(package_info["dependencies"], package_info["optional_dependencies"])

def translate_to_transitive_closure(importers, packages, prod = False, dev = False, no_optional = False):
    """Implementation detail of translate_package_lock, converts pnpm-lock to a different dictionary with more data.

    Args:
        importers: workspace projects (pnpm "importers")
        packages: all package info by name
        prod: If true, only install dependencies
        dev: If true, only install devDependencies
        no_optional: If true, optionalDependencies are not installed

    Returns:
        Nested dictionary suitable for further processing in our repository rule
    """

    # Packages resolved to a different version
    package_version_map = {}

    # tarbal versions
    for package_key, package_info in packages.items():
        if package_info["resolution"].get("tarball", None) and package_info["resolution"]["tarball"].startswith("file:"):
            package_version_map[package_key] = package_info

    # Collect deps of each importer (workspace projects)
    importers_deps = {}
    for importPath in importers.keys():
        lock_importer = importers[importPath]
        prod_deps = {} if dev else lock_importer.get("dependencies")
        dev_deps = {} if prod else lock_importer.get("dev_dependencies")
        opt_deps = {} if no_optional else lock_importer.get("optional_dependencies")

        deps = dicts.add(prod_deps, opt_deps)
        all_deps = dicts.add(prod_deps, dev_deps, opt_deps)

        # Package versions mapped to alternate versions
        for info in package_version_map.values():
            if info["name"] in deps:
                deps[info["name"]] = info["version"]
            if info["name"] in all_deps:
                all_deps[info["name"]] = info["version"]

        importers_deps[importPath] = {
            # deps this importer should pass on if it is linked as a first-party package; this does
            # not include devDependencies
            "deps": deps,
            # all deps of this importer to link in the node_modules folder of that Bazel package and
            # make available to all build targets; this includes devDependencies
            "all_deps": all_deps,
        }

    # Collect transitive dependencies for each package
    cache = {}
    for package in packages.keys():
        transitive_closure = gather_transitive_closure(
            packages,
            package,
            no_optional,
            cache,
        )

        packages[package]["transitive_closure"] = transitive_closure
        cache[package] = transitive_closure

    return (importers_deps, packages)
