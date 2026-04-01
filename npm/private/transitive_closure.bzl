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

    is_circular = False
    transitive_closure = {}
    transitive_optional_closure = {}

    # The package always references itself by its own name
    transitive_closure[package] = [root_package["name"]]

    stack = [(False, package)]
    iteration_max = 999999
    for i in range(0, iteration_max + 1):
        if not len(stack):
            break
        if i == iteration_max:
            msg = "gather_transitive_closure exhausted the iteration limit of {} - please report this issue".format(iteration_max)
            fail(msg)
        stack_optional, stack_package = stack.pop()
        stack_package = packages[stack_package]
        for dep_type in ["dependencies", "optional_dependencies"]:
            dep_optional = stack_optional or dep_type == "optional_dependencies"
            closure = transitive_optional_closure if dep_optional else transitive_closure

            for name, dep_key in stack_package[dep_type].items():
                if dep_key == package:
                    is_circular = True
                    continue

                # Already recorded this version of the dependency
                if dep_key in closure and name in closure[dep_key]:
                    continue
                closure[dep_key] = closure.get(dep_key, [])
                closure[dep_key].append(name)

                if dep_key.startswith("link:"):
                    # we don't need to drill down through first-party links for the transitive closure since there are no cycles
                    # allowed in first-party links
                    continue

                if dep_key not in packages:
                    msg = "Unknown package key: {} in {}".format(dep_key, packages.keys())
                    fail(msg)

                if dep_key in cache:
                    # Already computed for this dep, merge the cached results

                    dep_is_circular, dep_transitive_closure, dep_transitive_optional_closure = cache[dep_key]
                    if dep_is_circular:
                        is_circular = True

                    # deps merged into the 'closure' we're working on (which might be optional)
                    for transitive_name in dep_transitive_closure.keys():
                        closure[transitive_name] = closure.get(transitive_name, [])
                        for transitive_version in dep_transitive_closure[transitive_name]:
                            if transitive_version not in closure[transitive_name]:
                                closure[transitive_name].append(transitive_version)

                    # optional deps always merged into the optional closure
                    for transitive_name in dep_transitive_optional_closure.keys():
                        for transitive_version in dep_transitive_optional_closure[transitive_name]:
                            transitive_optional_closure[transitive_name] = transitive_optional_closure.get(transitive_name, [])
                            if transitive_version not in transitive_optional_closure[transitive_name]:
                                transitive_optional_closure[transitive_name].append(transitive_version)
                else:
                    # Recurse into the next level of dependencies
                    stack.append((dep_optional, dep_key))

    return is_circular, transitive_closure, transitive_optional_closure

def calculate_transitive_closures(packages):
    """Calculate the transitive closure of dependencies for each package.

    Args:
        packages: all package info by name
    """

    # A cache of [has_cycle, transitive_closure, transitive_closure_optional]
    # keyed by package key.
    cache = {}

    # Initial cache can be filled with trivial no-dependency packages.
    for package_key, package in packages.items():
        if not package["dependencies"] and not package["optional_dependencies"]:
            cache[package_key] = (False, {package_key: [package["name"]]}, {})

    for package in packages.keys():
        is_circular, transitive_closure, transitive_optional_closure = gather_transitive_closure(
            packages,
            package,
            cache,
        )

        if is_circular:
            packages[package]["transitive_closure"] = utils.sorted_map(transitive_closure)
            packages[package]["transitive_optional_closure"] = utils.sorted_map(transitive_optional_closure)

        cache[package] = (is_circular, transitive_closure, transitive_optional_closure)
