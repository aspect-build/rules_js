"""Helpers for RunfilesGroupInfo analysis tests.

Reads groups through rules_runfiles_group APIs. Does not reimplement grouping.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")

ENABLED_CONFIG = {
    str(Label("@rules_runfiles_group//runfiles_group:enabled")): True,
}

DISABLED_CONFIG = {
    str(Label("@rules_runfiles_group//runfiles_group:enabled")): False,
}

def resolve_target(ctx, target):
    return runfiles_groups.resolve(ctx, target, aspect_hints = [])

def group_by_name(resolved):
    found = {}
    if resolved == None:
        return found
    for g in resolved.groups:
        found[runfiles_groups.name_str(g.name)] = g
    return found

def files_list(group):
    if group == None:
        return []
    return runfiles_groups.files(group).to_list()

def file_set(files):
    result = {}
    for f in files:
        result[f] = True
    return result

def assert_no_rgi(env, target, msg = "expected no RunfilesGroupInfo"):
    asserts.false(env, RunfilesGroupInfo in target, msg)

def assert_has_rgi(env, target):
    asserts.true(env, RunfilesGroupInfo in target, "expected RunfilesGroupInfo")

def assert_executable_group(env, target, expected):
    asserts.equals(env, expected, target[RunfilesGroupInfo].executable_group)

def assert_group_metadata(env, group, *, kind, rank, do_not_merge, merge_affinity, weight = None):
    asserts.equals(env, kind, group.kind)
    asserts.equals(env, rank, group.rank)
    asserts.equals(env, do_not_merge, group.do_not_merge)
    asserts.equals(env, merge_affinity, group.merge_affinity)
    asserts.equals(env, weight, group.weight)

def assert_contains_files(env, group, expected_files, msg = None):
    have = file_set(files_list(group))
    for f in expected_files:
        asserts.true(env, f in have, msg or "missing {} in {}".format(f, group.name))

def assert_excludes_files(env, group, forbidden_files, msg = None):
    have = file_set(files_list(group))
    for f in forbidden_files:
        asserts.false(env, f in have, msg or "unexpected {} in {}".format(f, group.name))

def assert_files_exact(env, group, expected_files):
    have = file_set(files_list(group))
    want = file_set(expected_files)
    asserts.equals(env, len(want), len(have), "file count {} != {}".format(len(have), len(want)))
    for f in want:
        asserts.true(env, f in have, "missing {} in {}".format(f.path, group.name))
    for f in have:
        asserts.true(env, f in want, "unexpected {} in {}".format(f.path, group.name))

def assert_name_absent(env, found, name):
    asserts.false(env, name in found, "unexpected group {}".format(name))

def assert_empty_files(env, group):
    asserts.equals(env, [], files_list(group))

def overlap_pairs(resolved):
    """Return {file: [group names]} for files in more than one group."""
    owners = {}
    if resolved == None:
        return owners
    for g in resolved.groups:
        name = runfiles_groups.name_str(g.name)
        for f in runfiles_groups.files(g).to_list():
            names = owners.get(f)
            if names == None:
                owners[f] = [name]
            else:
                names.append(name)
    overlaps = {}
    for f, names in owners.items():
        if len(names) > 1:
            overlaps[f] = sorted(names)
    return overlaps

def assert_allowed_overlaps(env, resolved, allowed):
    """allowed is a list of sorted name-lists that may share a File."""
    allowed_keys = {",".join(names): True for names in allowed}
    for f, names in overlap_pairs(resolved).items():
        key = ",".join(names)
        asserts.true(
            env,
            key in allowed_keys,
            "unexpected overlap of {} on {}".format(names, f.path),
        )

def related_admitted(runfiles_files, original):
    """Admitted Files matching original by identity, copy association, or unique basename.

    Extra analysistest File attrs are not in the target's configuration. Identity
    works for source Files; generated Files fall back to a unique basename in
    this target's runfiles. Two unrelated Files that share a basename (two
    `shared.js` roots) match by identity only.
    """
    related = [f for f in runfiles_files if f == original]
    same = [f for f in runfiles_files if f.basename == original.basename]
    if related:
        for f in same:
            if f not in related and f.is_source != original.is_source:
                related.append(f)
        return related
    if len(same) == 1:
        return same
    return []

def runfiles_files(target):
    rf = target[DefaultInfo].default_runfiles
    if rf == None or rf.files == None:
        return []
    return rf.files.to_list()

def semantics_test(impl, attrs = {}):
    return analysistest.make(impl, attrs = attrs, config_settings = ENABLED_CONFIG)

def disabled_test(impl, attrs = {}):
    return analysistest.make(impl, attrs = attrs, config_settings = DISABLED_CONFIG)
