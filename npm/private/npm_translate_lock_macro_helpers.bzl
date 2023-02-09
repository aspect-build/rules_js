"Helper methods for the npm_translate_lock macro"

load("@bazel_skylib//lib:dicts.bzl", "dicts")

def _macro_lifecycle_args_to_rule_attrs(lifecycle_hooks, lifecycle_hooks_exclude, run_lifecycle_hooks, lifecycle_hooks_no_sandbox, lifecycle_hooks_execution_requirements):
    """Convert lifecycle-related macro args into attribute values to pass to the rule"""

    # lifecycle_hooks_exclude is a convenience attribute to set `<value>: []` in `lifecycle_hooks`
    lifecycle_hooks = dict(lifecycle_hooks)
    for p in lifecycle_hooks_exclude:
        if p in lifecycle_hooks:
            fail("expected '{}' to be in only one of lifecycle_hooks or lifecycle_hooks_exclude".format(p))
        lifecycle_hooks[p] = []

    # run_lifecycle_hooks is a convenience attribute to set `"*": ["preinstall", "install", "postinstall"]` in `lifecycle_hooks`
    if run_lifecycle_hooks:
        if "*" not in lifecycle_hooks:
            lifecycle_hooks = dicts.add(lifecycle_hooks, {"*": ["preinstall", "install", "postinstall"]})

    # lifecycle_hooks_no_sandbox is a convenience attribute to set `"*": ["no-sandbox"]` in `lifecycle_hooks_execution_requirements`
    if lifecycle_hooks_no_sandbox:
        if "*" not in lifecycle_hooks_execution_requirements:
            lifecycle_hooks_execution_requirements = dicts.add(lifecycle_hooks_execution_requirements, {"*": []})
        if "no-sandbox" not in lifecycle_hooks_execution_requirements["*"]:
            lifecycle_hooks_execution_requirements["*"].append("no-sandbox")

    return lifecycle_hooks, lifecycle_hooks_execution_requirements

helpers = struct(
    macro_lifecycle_args_to_rule_attrs = _macro_lifecycle_args_to_rule_attrs,
)
