"nodejs_package rule"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_nodejs//nodejs:providers.bzl", "LinkablePackageInfo", "declaration_info",)

_DOC = """Defines a library that executes in a node.js runtime.
    
The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

To be compatible with Bazel's remote execution protocol,
all source files are copied to an an output directory,
which is 

NB: This rule is not yet tested on Windows
"""

_ATTRS = {
    "src": attr.label(
        allow_single_file = True,
        doc = """A TreeArtifact containing the npm package files.
        
        Exactly one of `src` or `srcs` should be set.
        """,
    ),
    "srcs": attr.label_list(
        allow_files = True,
        doc = """Files to copy into the package directory.
        
        Exactly one of `src` or `srcs` should be set.
        """,
    ),
    "deps": attr.label_list(
        doc = """Other packages this one depends on.

        This should include *all* modules the program may need at runtime.
        
        > In typical usage, a node.js program sometimes requires modules which were
        > never declared as dependencies.
        > This pattern is typically used when the program has conditional behavior
        > that is enabled when the module is found (like a plugin) but the program
        > also runs without the dependency.
        > 
        > This is possible because node.js doesn't enforce the dependencies are sound.
        > All files under `node_modules` are available to any program.
        > In contrast, Bazel makes it possible to make builds hermetic, which means that
        > all dependencies of a program must be declared when running in Bazel's sandbox.
        """,
    ),
    "package_name": attr.string(
        doc = "Must match the `name` field in the `package.json` file for this package.",
        mandatory = True,
    ),
    "remap_paths": attr.string_dict(),
    "is_windows": attr.bool(mandatory = True),
}

# Hints for Bazel spawn strategy
_execution_requirements = {
    # Copying files is entirely IO-bound and there is no point doing this work remotely.
    # Also, remote-execution does not allow source directory inputs, see
    # https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
    # So we must not attempt to execute remotely in that case.
    "no-remote-exec": "1",
}

def _dst_path(ctx, src, dst, remap_paths):
    flat_path = src.path if src.is_source else "/".join(src.path.split("/")[3:])
    dst_path = flat_path
    for k, v in remap_paths.items():
        k = k.strip()
        v = v.strip().strip("/")
        if not k:
            fail("invalid empty key in remap_paths")

        # determine if it is path relative to the current package
        is_relative = not k.startswith("/")
        k = k.strip("/")

        # allow for relative paths expressed with ./path
        if k.startswith("./"):
            k = k[2:]

        # if relative add the package name to the path
        if is_relative and ctx.label.package:
            k = "/".join([ctx.label.package, k])

        # if flat_path starts with key then substitute key for value
        if flat_path.startswith(k):
            dst_path = v + flat_path[len(k):] if v else flat_path[len(k) + 1:]
    return dst.path + "/" + dst_path

def _copy_bash(ctx, srcs, dst):
    cmds = [
        "set -o errexit -o nounset -o pipefail",
        "mkdir -p \"%s\"" % dst.path,
    ]
    for src in srcs:
        dst_path = _dst_path(ctx, src, dst, ctx.attr.remap_paths)
        cmds.append("""
if [[ ! -e "{src}" ]]; then echo "file '{src}' does not exist"; exit 1; fi
if [[ -f "{src}" ]]; then
    mkdir -p "{dst_dir}"
    cp -f "{src}" "{dst}"
else
    mkdir -p "{dst}"
    cp -rf "{src}/" "{dst}"
fi
""".format(src = src.path, dst_dir = paths.dirname(dst_path), dst = dst_path))
        # print("%s -> %s" % (src.path, dst_path))

    ctx.actions.run_shell(
        inputs = srcs,
        outputs = [dst],
        command = "\n".join(cmds),
        mnemonic = "PkgNpm",
        progress_message = "Copying files to nodejs_package directory",
        use_default_shell_env = True,
        execution_requirements = _execution_requirements,
    )

def _nodejs_package_impl(ctx):
    if ctx.attr.src and ctx.attr.srcs:
        fail("Only one of src or srcs may be set")
    if not ctx.attr.src and not ctx.attr.srcs:
        fail("At least one of src or srcs must be set")
    if ctx.attr.src and not ctx.file.src.is_directory:
        fail("src must be a directory (a TreeArtifact produced by another rule)")

    package_name = ctx.attr.package_name.strip()
    if not package_name:
        fail("package_name attr must not be empty")
    if ctx.attr.srcs:
        output = ctx.actions.declare_directory(package_name)
        if ctx.attr.is_windows:
            fail("not yet implemented")
        else:
            _copy_bash(ctx, ctx.files.srcs, output)
    else:
        output = ctx.file.src

    files = depset(direct = [output])
    runfiles = ctx.runfiles(
        files = [output],
        transitive_files = depset([output]),
        root_symlinks = {
            "node_modules/" + package_name: output,
        },
    )
    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(dep[DefaultInfo].data_runfiles)
    return [
        DefaultInfo(files = files, runfiles = runfiles),
        LinkablePackageInfo(package_name = ctx.attr.package_name, files = [output]),
        # TODO: figure this out why we need this
        declaration_info(
            declarations = files,
            deps = ctx.attr.deps,
        )
    ]

nodejs_package_lib = struct(
    attrs = _ATTRS,
    nodejs_package_impl = _nodejs_package_impl,
    provides = [DefaultInfo],
)

# For stardoc to generate documentation for the rule rather than a wrapper macro
nodejs_package = rule(
    doc = _DOC,
    implementation = nodejs_package_lib.nodejs_package_impl,
    attrs = nodejs_package_lib.attrs,
    provides = nodejs_package_lib.provides,
)
