load("@rules_nodejs//nodejs:providers.bzl", "LinkablePackageInfo")

def _compiler(ctx):

    symlinks = []

    for dep in ctx.attr.deps:   
        runfiles = dep[DefaultInfo].default_runfiles
        for symlink in runfiles.root_symlinks.to_list():
            output = ctx.actions.declare_file(symlink.path)
            symlinks.append(output)
            ctx.actions.symlink(
                output = output,
                target_file = symlink.target_file
            )
            print(output.path)

    inputs = depset(symlinks)

    inputs = depset(ctx.files.deps, transitive = [inputs])


    file_to_generate = ctx.actions.declare_file("test.txt")

    args = ctx.actions.args()
    args.add(file_to_generate.path)

    ctx.actions.run(
        inputs = inputs,
        executable = ctx.executable._compiler,
        arguments = [args],
        outputs = [file_to_generate],
        env = {
            "NODE_PATH": "/".join([ctx.bin_dir.path, ctx.label.package, "node_modules"])
        }
    )

    return [
        DefaultInfo(files = depset([file_to_generate]))
    ]
    


compiler = rule(
    implementation = _compiler,
    attrs = {
        "deps": attr.label_list(),
        "_compiler": attr.label(
            default = "//dyn/compiler:bin",
            executable = True,
            cfg = "exec"
        )
    }
)
