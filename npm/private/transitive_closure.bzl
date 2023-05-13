"Helper utility for working with pnpm lockfile"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":utils.bzl", "utils")

def gather_transitive_closure(packages, no_optional, direct_deps, transitive_closure):
    """Walk the dependency tree, collecting the transitive closure of dependencies and their versions.

    This is needed to resolve npm dependency cycles.
    Note: Starlark expressly forbids recursion and infinite loops, so we need to iterate over a large range of numbers,
    where each iteration takes one item from the stack, and possibly adds many new items to the stack.

    Args:
        packages: dictionary from pnpm lock
        no_optional: whether to exclude optionalDependencies
        direct_deps: the immediate dependencies of a given package
        transitive_closure: a dictionary which is mutated as the return value
    """
    stack = [direct_deps]
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
            if version[0].isdigit():
                package_key = utils.pnpm_name(name, version)
            elif version.startswith("/"):
                # an aliased dependency
                version = version[1:]
                package_key = version
                name, version = utils.parse_pnpm_name(version)
            else:
                package_key = version
            transitive_closure[name] = transitive_closure.get(name, [])
            if version in transitive_closure[name]:
                continue
            transitive_closure[name].insert(0, version)
            if package_key.startswith("link:"):
                # we don't need to drill down through first-party links for the transitive closure since there are no cycles
                # allowed in first-party links
                continue
            else:
                package_info = packages[package_key]
            stack.append(package_info["dependencies"] if no_optional else dicts.add(package_info["dependencies"], package_info["optional_dependencies"]))

def _gather_package_info(package_path, package_snapshot):
    if package_path.startswith("/"):
        # an aliased dependency
        package = package_path[1:]
        name, version = utils.parse_pnpm_name(package)
        friendly_version = utils.strip_peer_dep_or_patched_version(version)
        package_key = package
    elif package_path.startswith("file:") and utils.is_vendored_tarfile(package_snapshot):
        if "name" not in package_snapshot:
            fail("expected package %s to have a name field" % package_path)
        name = package_snapshot["name"]
        package = package_snapshot["name"]
        version = package_path
        if "version" in package_snapshot:
            version = package_snapshot["version"]
        package_key = "{}/{}".format(package, version)
        friendly_version = version
    elif package_path.startswith("file:"):
        package = package_path
        if "name" not in package_snapshot:
            msg = "expected package {} to have a name field".format(package_path)
            fail(msg)
        name = package_snapshot["name"]
        version = package_path
        friendly_version = package_snapshot["version"] if "version" in package_snapshot else version
        package_key = package
    else:
        package = package_path
        if "name" not in package_snapshot:
            msg = "expected package {} to have a name field".format(package_path)
            fail(msg)
        if "version" not in package_snapshot:
            msg = "expected package {} to have a version field".format(package_path)
            fail(msg)
        name = package_snapshot["name"]
        version = package_path
        friendly_version = package_snapshot["version"]
        package_key = package

    if "resolution" not in package_snapshot:
        msg = "package {} has no resolution field".format(package_path)
        fail(msg)
    id = package_snapshot["id"] if "id" in package_snapshot else None
    resolution = package_snapshot["resolution"]

    return package_key, {
        "name": name,
        "id": id,
        "version": version,
        "friendly_version": friendly_version,
        "resolution": resolution,
        "dependencies": package_snapshot.get("dependencies", {}),
        "optional_dependencies": package_snapshot.get("optionalDependencies", {}),
        "dev": package_snapshot.get("dev", False),
        "optional": package_snapshot.get("optional", False),
        "patched": package_snapshot.get("patched", False),
        "has_bin": package_snapshot.get("hasBin", False),
        "requires_build": package_snapshot.get("requiresBuild", False),
    }

def translate_to_transitive_closure(lock_importers, lock_packages, prod = False, dev = False, no_optional = False):
    """Implementation detail of translate_package_lock, converts pnpm-lock to a different dictionary with more data.

    Args:
        lock_importers: lockfile importers dict
        lock_packages: lockfile packages dict
        prod: If true, only install dependencies
        dev: If true, only install devDependencies
        no_optional: If true, optionalDependencies are not installed

    Returns:
        Nested dictionary suitable for further processing in our repository rule
    """
    packages = {}
    for package_path, package_snapshot in lock_packages.items():
        package, package_info = _gather_package_info(package_path, package_snapshot)
        packages[package] = package_info

    tar_packages = {
        p: info
        for p, info in packages.items()
        if info["resolution"].get("tarball") and info["resolution"]["tarball"].startswith("file:")
    }
    importers = {}
    for importPath in lock_importers.keys():
        lock_importer = lock_importers[importPath]
        prod_deps = {} if dev else lock_importer.get("dependencies", {})
        dev_deps = {} if prod else lock_importer.get("devDependencies", {})
        opt_deps = {} if no_optional else lock_importer.get("optionalDependencies", {})

        transitive_deps = dicts.add(prod_deps, opt_deps)
        all_deps = dicts.add(prod_deps, dev_deps, opt_deps)

        for info in tar_packages.values():
            if info["name"] in transitive_deps:
                transitive_deps[info["name"]] = info["version"]
            if info["name"] in all_deps:
                all_deps[info["name"]] = info["version"]

        importers[importPath] = {
            # deps this importer should pass on if it is linked as a first-party package; this does
            # not include devDependencies
            "transitive_deps": transitive_deps,
            # all deps of this importer to link in the node_modules folder of that Bazel package and
            # make available to all build targets; this includes devDependencies
            "all_deps": all_deps,
        }

    for package in packages.keys():
        package_info = packages[package]
        transitive_closure = {}
        transitive_closure[package_info["name"]] = [package_info["version"]]
        dependencies = package_info["dependencies"] if no_optional else dicts.add(package_info["dependencies"], package_info["optional_dependencies"])

        gather_transitive_closure(
            packages,
            no_optional,
            dependencies,
            transitive_closure,
        )

        package_info["transitive_closure"] = transitive_closure

        # final_transitive_closure = {}
        # for package_name in transitive_closure.keys():
        #     found = False
        #     for package in packages.keys():
        #         if package_name == packages[package]["name"]:
        #             found = True
        #     if found:
        #         final_transitive_closure[package_name] = transitive_closure[package_name]
        #     else:
        #         print("filtered out {}".format(package_name))

        # package_info["transitive_closure"] = final_transitive_closure

    return (importers, packages)
