"Helper utility for working with pnpm lockfile"

load(":utils.bzl", "utils")

def gather_transitive_closure(packages, snapshots, snapshot, no_optional, cache = {}):
    """Walk the dependency tree, collecting the transitive closure of dependencies and their versions.

    This is needed to resolve npm dependency cycles.
    Note: Starlark expressly forbids recursion and infinite loops, so we need to iterate over a large range of numbers,
    where each iteration takes one item from the stack, and possibly adds many new items to the stack.

    Args:
        packages: all packages
        snapshots: all snapshots
        snapshot: the package snapshot to collect deps for
        no_optional: whether to exclude optionalDependencies
        cache: a dictionary of results from previous invocations

    Returns:
        A dictionary of transitive dependencies, mapping package names to dependent versions.
    """
    root_package = packages[snapshots[snapshot]["package"]]

    transitive_closure = {}
    transitive_closure[snapshot] = [root_package["name"]]

    stack = [_get_snapshot_deps(snapshots[snapshot], no_optional)]
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
            elif dep_key in snapshots:
                # Recurse into the next level of dependencies
                stack.append(_get_snapshot_deps(snapshots[dep_key], no_optional))
            else:
                msg = "Unknown package key: {} in {}".format(dep_key, snapshots.keys())
                fail(msg)

    return utils.sorted_map(transitive_closure)

def _get_snapshot_deps(snapshot, no_optional):
    return snapshot["dependencies"] if no_optional else snapshot["dependencies"] | snapshot["optional_dependencies"]

def translate_to_transitive_closure(importers, packages, snapshots, prod = False, dev = False, no_optional = False):
    """Implementation detail of translate_package_lock, converts pnpm-lock to a different dictionary with more data.

    Args:
        importers: workspace projects (pnpm "importers")
        packages: all package info by name
        snapshots: snapshots
        prod: If true, only install dependencies
        dev: If true, only install devDependencies
        no_optional: If true, optionalDependencies are not installed

    Returns:
        Nested dictionary suitable for further processing in our repository rule
    """

    # Collect deps of each importer (workspace projects)
    importers_deps = {}
    for importPath in importers.keys():
        lock_importer = importers[importPath]
        prod_deps = {} if dev else lock_importer["dependencies"]
        dev_deps = {} if prod else lock_importer["dev_dependencies"]
        opt_deps = {} if no_optional else lock_importer["optional_dependencies"]

        deps = prod_deps | opt_deps
        all_deps = prod_deps | dev_deps | opt_deps

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
    for snapshot in snapshots.keys():
        transitive_closure = gather_transitive_closure(
            packages,
            snapshots,
            snapshot,
            no_optional,
            cache,
        )

        snapshots[snapshot]["transitive_closure"] = transitive_closure
        cache[snapshot] = transitive_closure

    return (importers_deps, packages, snapshots)
