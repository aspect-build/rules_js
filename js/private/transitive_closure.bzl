"Helper utility for working with pnpm lockfile"

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:types.bzl", "types")
load("//js/private:pnpm_utils.bzl", "pnpm_utils")

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
            fail("gather_transitive_closure exhausted the iteration limit of %s - please report this issue" % iteration_max)
        deps = stack.pop()
        for name in deps.keys():
            version = deps[name]
            transitive_closure[name] = transitive_closure.get(name, [])
            if version in transitive_closure[name]:
                continue
            transitive_closure[name].insert(0, version)
            package_info = packages[pnpm_utils.pnpm_name(name, version)]
            stack.append(package_info["dependencies"] if no_optional else dicts.add(package_info["dependencies"], package_info["optionalDependencies"]))

def translate_to_transitive_closure(lockfile, prod = False, dev = False, no_optional = False):
    """Implementation detail of translate_package_lock, converts pnpm-lock to a different dictionary with more data.

    Args:
        lockfile: a starlark dictionary representing the pnpm lockfile
        prod: If true, only install dependencies
        dev: If true, only install devDependencies
        no_optional: If true, optionalDependencies are not installed

    Returns:
        Nested dictionary suitable for further processing in our repository rule
    """
    if not types.is_dict(lockfile):
        fail("lockfile should be a starlark dict")
    if "lockfileVersion" not in lockfile.keys():
        fail("expected lockfileVersion key in lockfile")
    if "packages" not in lockfile.keys():
        fail("expected packages key in lockfile")
    pnpm_utils.assert_lockfile_version(lockfile["lockfileVersion"])

    lock_importers = lockfile.get("importers", {
        ".": {
            "specifiers": lockfile.get("specifiers", {}),
            "dependencies": lockfile.get("dependencies", {}),
            "optionalDependencies": lockfile.get("optionalDependencies", {}),
            "devDependencies": lockfile.get("devDependencies", {}),
        },
    })
    lock_packages = lockfile.get("packages")

    if "." not in lock_importers.keys():
        fail("no root importers in lockfile")

    root_importers = lock_importers["."]

    importers = {}
    for importPath in lock_importers.keys():
        lock_importer = lock_importers[importPath]
        prod_deps = {} if dev else lock_importer.get("dependencies", {})
        dev_deps = {} if prod else lock_importer.get("devDependencies", {})
        opt_deps = {} if no_optional else lock_importer.get("optionalDependencies", {})
        importers[importPath] = {
            "dependencies": dicts.add(prod_deps, dev_deps, opt_deps),
        }

    packages = {}
    for package_path in lock_packages.keys():
        package_snapshot = lock_packages[package_path]
        if not package_path.startswith("/"):
            fail("unsupported package path " + package_path)
        package = package_path[1:]
        [name, pnpmVersion] = pnpm_utils.parse_pnpm_name(package)

        if "resolution" not in package_snapshot.keys():
            fail("package %s has no resolution field" % package_path)
        resolution = package_snapshot["resolution"]
        if "integrity" not in resolution.keys():
            fail("package %s has no integrity field" % package_path)

        packages[package] = {
            "name": name,
            "pnpmVersion": pnpmVersion,
            "integrity": resolution["integrity"],
            "dependencies": package_snapshot.get("dependencies", {}),
            "optionalDependencies": package_snapshot.get("optionalDependencies", {}),
            "dev": "dev" in package_snapshot.keys(),
            "optional": "optional" in package_snapshot.keys(),
            "hasBin": "hasBin" in package_snapshot.keys(),
            "requiresBuild": "requiresBuild" in package_snapshot.keys(),
        }

    for package in packages.keys():
        package_info = packages[package]
        transitive_closure = {}
        transitive_closure[package_info["name"]] = [package_info["pnpmVersion"]]
        dependencies = package_info["dependencies"] if no_optional else dicts.add(package_info["dependencies"], package_info["optionalDependencies"])

        gather_transitive_closure(
            packages,
            no_optional,
            dependencies,
            transitive_closure,
        )

        package_info["transitiveClosure"] = transitive_closure

    return {
        "importers": importers,
        "packages": packages,
    }
