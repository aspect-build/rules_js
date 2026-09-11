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
    overlaps = {}
    for f, names in file_owners(resolved).items():
        if len(names) > 1:
            overlaps[f] = names
    return overlaps

def file_owners(resolved):
    """Return {file: sorted group names} for every File on a resolved group."""
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
    result = {}
    for f, names in owners.items():
        result[f] = sorted(names)
    return result

def assert_exact_file_owners(env, owners, files, expected_names, msg = None):
    want = sorted(expected_names)
    for f in files:
        got = owners.get(f, [])
        asserts.equals(env, want, got, msg or "{} owners {} != {}".format(f.path, got, want))

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

def assert_overlap_files(env, resolved, allowed):
    """allowed is {file: sorted names} for every File that may appear in multiple groups."""
    for f, names in overlap_pairs(resolved).items():
        want = allowed.get(f)
        asserts.true(env, want != None, "unexpected overlap of {} on {}".format(names, f.path))
        asserts.equals(env, want, names, "overlap owners for {} were {}".format(f.path, names))

def assert_grouped_runfiles_match(env, ctx, resolved, target):
    """Resolved groups' four runfiles components equal the target's default_runfiles."""
    rf = target[DefaultInfo].default_runfiles
    g_files = {}
    g_empty = {}
    g_sym = {}
    g_root = {}
    if resolved != None:
        for g in resolved.groups:
            gr = runfiles_groups.runfiles(ctx, g)
            if gr.files:
                for f in gr.files.to_list():
                    g_files[f] = True
            if gr.empty_filenames:
                for n in gr.empty_filenames.to_list():
                    g_empty[n] = True
            if gr.symlinks:
                for s in gr.symlinks.to_list():
                    g_sym[(s.path, s.target_file)] = True
            if gr.root_symlinks:
                for s in gr.root_symlinks.to_list():
                    g_root[(s.path, s.target_file)] = True
    want_files = file_set(rf.files.to_list() if rf != None and rf.files else [])
    want_empty = {}
    if rf != None and rf.empty_filenames:
        for n in rf.empty_filenames.to_list():
            want_empty[n] = True
    want_sym = {}
    if rf != None and rf.symlinks:
        for s in rf.symlinks.to_list():
            want_sym[(s.path, s.target_file)] = True
    want_root = {}
    if rf != None and rf.root_symlinks:
        for s in rf.root_symlinks.to_list():
            want_root[(s.path, s.target_file)] = True
    asserts.equals(env, len(want_files), len(g_files), "grouped file count {} != runfiles {}".format(len(g_files), len(want_files)))
    for f in want_files:
        asserts.true(env, f in g_files, "grouped missing {}".format(f.path))
    for f in g_files:
        asserts.true(env, f in want_files, "grouped extra {}".format(f.path))
    asserts.equals(env, sorted(want_empty.keys()), sorted(g_empty.keys()))
    asserts.equals(env, len(want_sym), len(g_sym), "grouped symlink count {} != runfiles {}".format(len(g_sym), len(want_sym)))
    for key in want_sym:
        asserts.true(env, key in g_sym, "grouped missing symlink {} -> {}".format(key[0], key[1].path))
    for key in g_sym:
        asserts.true(env, key in want_sym, "grouped extra symlink {} -> {}".format(key[0], key[1].path))
    asserts.equals(env, len(want_root), len(g_root), "grouped root symlink count {} != runfiles {}".format(len(g_root), len(want_root)))
    for key in want_root:
        asserts.true(env, key in g_root, "grouped missing root symlink {} -> {}".format(key[0], key[1].path))
    for key in g_root:
        asserts.true(env, key in want_root, "grouped extra root symlink {} -> {}".format(key[0], key[1].path))

def unique_admitted(runfiles_files, basename):
    """Same-configuration Files from this target's runfiles with an exact basename."""
    return [f for f in runfiles_files if f.basename == basename]

def related_admitted(runfiles_files, original):
    """Admitted Files matching original by identity, plus copies of that File.

    Extra analysistest File attrs are not in the target's configuration. Use
    this only with source Files (same configuration) or with Files already taken
    from the target under test. Do not match unrelated same-basename Files.
    """
    related = [f for f in runfiles_files if f == original]
    if not related:
        return []
    for f in runfiles_files:
        if f not in related and f.basename == original.basename and f.is_source != original.is_source:
            related.append(f)
    return related

def runfiles_files(target):
    rf = target[DefaultInfo].default_runfiles
    if rf == None or rf.files == None:
        return []
    return rf.files.to_list()

def semantics_test(impl, attrs = {}):
    return analysistest.make(impl, attrs = attrs, config_settings = ENABLED_CONFIG)

def disabled_test(impl, attrs = {}):
    return analysistest.make(impl, attrs = attrs, config_settings = DISABLED_CONFIG)
