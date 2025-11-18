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
        A dictionary of transitive dependencies, mapping package keys to package names/aliases
    """
    root_package = packages[package]

    transitive_closure = {}
    transitive_closure[package] = [root_package["name"]]

    stack = [_get_package_info_deps(root_package)]
    iteration_max = 999999
    for i in range(0, iteration_max + 1):
        if not len(stack):
            break
        if i == iteration_max:
            msg = "gather_transitive_closure exhausted the iteration limit of {} - please report this issue".format(iteration_max)
            fail(msg)
        deps = stack.pop()
        for name, dep_key in deps.items():
            transitive_closure[dep_key] = transitive_closure.get(dep_key, [])
            if name in transitive_closure[dep_key]:
                continue
            transitive_closure[dep_key].append(name)

            if dep_key.startswith("link:"):
                # we don't need to drill down through first-party links for the transitive closure since there are no cycles
                # allowed in first-party links
                continue

            if dep_key in cache:
                # Already computed for this dep, merge the cached results
                for transitive_name in cache[dep_key].keys():
                    transitive_closure[transitive_name] = transitive_closure.get(transitive_name, [])
                    for transitive_version in cache[dep_key][transitive_name]:
                        if transitive_version not in transitive_closure[transitive_name]:
                            transitive_closure[transitive_name].append(transitive_version)
            elif dep_key in packages:
                # Recurse into the next level of dependencies
                stack.append(_get_package_info_deps(packages[dep_key]))
            else:
                msg = "Unknown package key: {} in {}".format(dep_key, packages.keys())
                fail(msg)

    return utils.sorted_map(transitive_closure)

def _get_package_info_deps(package_info):
    return package_info["dependencies"] | package_info["optional_dependencies"]

def calculate_transitive_closures(packages):
    """Calculate the transitive closure of dependencies for each package.

    Args:
        packages: all package info by name
    """

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
