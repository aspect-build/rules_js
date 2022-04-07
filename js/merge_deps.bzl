def merge_deps(ctx, tool_attr, dep_attr):
    """
    Collects third-party dependecies and merges them with first-party dependencies provides them as tools for actions to consume those dependecies.
    Args:
        ctx: Action context
        tool_attr:Name of the attribute to get tool from
        dep_attr: Name of the attribute to collect deps from
    """
    symlinks = []

    tool_runfiles = getattr(ctx.attr, tool_attr)[DefaultInfo].default_runfiles
    deps_runfiles = [dep[DefaultInfo].default_runfiles for dep in getattr(ctx.attr, dep_attr)]

    runfiles = tool_runfiles.merge_all(deps_runfiles)

    for symlink in runfiles.root_symlinks.to_list():
        output = ctx.actions.declare_file(symlink.path)
        symlinks.append(output)
        ctx.actions.symlink(
            output = output,
            target_file = symlink.target_file
        )
    
    tools = depset(getattr(ctx.files, dep_attr), transitive = [depset(symlinks)])

    env = {
        "NODE_PATH": "/".join([ctx.bin_dir.path, ctx.label.package, "node_modules"]),
        "MERGED_NODE_MODULES": "/".join([ctx.bin_dir.path, ctx.label.package, "node_modules"]),
    }
    return (tools, env)