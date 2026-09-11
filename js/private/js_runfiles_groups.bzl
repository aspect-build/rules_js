"""Optional RunfilesGroupInfo emission for rules_js producers.

Public producer API is RunfilesGroupInfo only. Grouping work is gated by
`runfiles_groups.is_enabled(ctx)`. Callers must merge `runfiles_groups.RULE_ATTRS`
into the rule attrs before calling `is_enabled`.
"""

load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load("//npm:providers.bzl", "NpmPackageInfo", "NpmPackageStoreInfo")
load(":js_info.bzl", "JsInfo")

# Named groups jointly supplied by multiple targets. Public convention.
AFFINITY = "aspect_rules_js"
FIRST_PARTY_GROUP = "aspect_rules_js#first_party"
THIRD_PARTY_GROUP = "aspect_rules_js#third_party"
NPM_GROUP = "aspect_rules_js#npm"
NPM_LINKS_GROUP = "aspect_rules_js#npm_links"
NODE_GROUP = "aspect_rules_js#node"
NODE_EXTERNAL_PREFIX = "aspect_rules_js#node_external:"
RUNTIME_SUPPORT_GROUP = "aspect_rules_js#runtime_support"
NPM_TOOLCHAIN_GROUP = "aspect_rules_js#npm_toolchain"
COVERAGE_GROUP = "aspect_rules_js#coverage"
UNCLASSIFIED_GROUP = "aspect_rules_js#unclassified"

RANK_FIRST_PARTY_DEPS = -50
RANK_NPM_LINKS = -200
RANK_UNCLASSIFIED = -300
RANK_BOOTSTRAP = -900

_CONSUMED_NAMES = {
    FIRST_PARTY_GROUP: True,
    THIRD_PARTY_GROUP: True,
    NPM_GROUP: True,
    NPM_LINKS_GROUP: True,
    UNCLASSIFIED_GROUP: True,
}

def _is_enabled(ctx):
    """True when grouping attrs are present and the global flag is on."""
    if not hasattr(ctx.attr, "_runfiles_group_enabled"):
        return False
    return runfiles_groups.is_enabled(ctx)

def _native_entry(name, content, kind, rank, do_not_merge = False):
    return runfiles_groups.entry(
        name = name,
        content = content,
        kind = kind,
        rank = rank,
        do_not_merge = do_not_merge,
        weight = None,
        merge_affinity = AFFINITY,
    )

def _maybe_files_entry(name, files, kind, rank, do_not_merge = False):
    """Files-only native entry, or None when the depset/list is empty (O(1))."""
    if not files:
        return None
    if type(files) != "depset":
        files = depset(files)
    return _native_entry(name, files, kind, rank, do_not_merge = do_not_merge)

def _depset_has_members(d):
    return d != None and bool(d.to_list())

def _runfiles_nonempty(runfiles):
    if runfiles == None:
        return False

    # Empty depsets are still truthy; inspect this one target's components.
    if _depset_has_members(runfiles.files):
        return True
    if _depset_has_members(runfiles.empty_filenames):
        return True
    if _depset_has_members(runfiles.symlinks):
        return True
    if _depset_has_members(runfiles.root_symlinks):
        return True
    return False

def _fallback_runfiles_entry(ctx, dep):
    runfiles = dep[DefaultInfo].default_runfiles
    if runfiles == None:
        runfiles = ctx.runfiles()
    if not _runfiles_nonempty(runfiles):
        return None
    return runfiles_groups.entry(name = dep.label, content = runfiles)

def _has_executable(target):
    """True for nested binaries, not for a lone File listed as its own executable."""
    files_to_run = target[DefaultInfo].files_to_run
    executable = files_to_run.executable if files_to_run else None
    if executable == None:
        return False
    files = target[DefaultInfo].files.to_list() if target[DefaultInfo].files else []
    if files == [executable]:
        return False
    return True

def _is_ordinary_data(target):
    if JsInfo in target:
        return False
    if NpmPackageInfo in target:
        return False
    if NpmPackageStoreInfo in target:
        return False
    if RunfilesGroupInfo in target:
        return False
    if _has_executable(target):
        return False
    return True

def _copy_map(originals, copies):
    """Map original File -> copy File (identity when not copied)."""
    mapping = {}
    for i, original in enumerate(originals):
        copy = copies[i] if i < len(copies) else original
        mapping[original] = copy
    return mapping

def _flatten_files(depsets):
    nonempty = [d for d in depsets if d]
    if not nonempty:
        return {}
    result = {}
    for f in depset(transitive = nonempty).to_list():
        result[f] = True
    return result

def _file_dict(files):
    result = {}
    for f in files:
        result[f] = True
    return result

def _lift(files_dict, copy_of, admitted):
    """Lift pre-copy roles through copy associations, then intersect with admitted Files."""
    result = {}
    for f in files_dict:
        if f in admitted:
            result[f] = True
        copy = copy_of.get(f)
        if copy != None and copy != f and copy in admitted:
            result[copy] = True
    return result

def _extend_with_copies(ctx, entry, copy_of, admitted):
    extras = []
    for f in runfiles_groups.files(entry).to_list():
        copy = copy_of.get(f)
        if copy != None and copy != f and copy in admitted:
            extras.append(copy)
    if not extras:
        return entry
    return runfiles_groups.derive(
        entry,
        content = runfiles_groups.union(ctx, [entry.content, depset(extras)]),
    )

def _collect_rgi(ctx, own, transitive, executable_group = None):
    if not own and not transitive:
        return None
    return RunfilesGroupInfo(
        entries = runfiles_groups.collect(ctx, deps = [], data = [], own = own, transitive = transitive),
        executable_group = executable_group,
    )

def _direct_files_and_copies(dep, copy_of):
    files = []
    for f in dep[DefaultInfo].files.to_list() if dep[DefaultInfo].files else []:
        files.append(f)
        copy = copy_of.get(f)
        if copy != None and copy != f:
            files.append(copy)
    return files

def _extra_default_outputs(dep, copy_of):
    """DefaultInfo.files not already in the target's default_runfiles, plus copies."""
    default_info = dep[DefaultInfo]
    runfiles = default_info.default_runfiles
    runfiles_files = {}
    if runfiles != None and runfiles.files:
        for f in runfiles.files.to_list():
            runfiles_files[f] = True
    extras = []
    for f in default_info.files.to_list() if default_info.files else []:
        if f not in runfiles_files:
            extras.append(f)
            copy = copy_of.get(f)
            if copy != None and copy != f:
                extras.append(copy)
    return extras

def library_groups(ctx, *, data, srcs_types_deps, copied_data_files, copied_originals):
    """Relay/classify a js_library's admitted default-runfiles contribution."""
    copy_of = _copy_map(copied_originals, copied_data_files)
    own = []
    transitive = []
    first_party = []
    third_party = []
    unclassified = []

    for dep in data:
        if RunfilesGroupInfo in dep:
            transitive.append(dep[RunfilesGroupInfo].entries)
            unclassified.extend(_extra_default_outputs(dep, copy_of))
        elif _is_ordinary_data(dep):
            first_party.extend(_direct_files_and_copies(dep, copy_of))
        elif JsInfo in dep or NpmPackageInfo in dep:
            first_party.extend(_direct_files_and_copies(dep, copy_of))
        else:
            fallback = _fallback_runfiles_entry(ctx, dep)
            if fallback:
                own.append(fallback)
        if NpmPackageInfo in dep:
            src = dep[NpmPackageInfo].src
            if src:
                third_party.append(src)
                copy = copy_of.get(src)
                if copy != None and copy != src:
                    third_party.append(copy)

    for dep in srcs_types_deps:
        if RunfilesGroupInfo in dep:
            transitive.append(dep[RunfilesGroupInfo].entries)
        elif JsInfo in dep or NpmPackageInfo in dep:
            # Inventories travel in JsInfo. Only default-runfiles files are admitted.
            rf = dep[DefaultInfo].default_runfiles
            if rf != None and _depset_has_members(rf.files):
                first_party.extend(rf.files.to_list())
            elif _depset_has_members(dep[DefaultInfo].files) and _runfiles_nonempty(rf):
                first_party.extend(_direct_files_and_copies(dep, copy_of))
        else:
            fallback = _fallback_runfiles_entry(ctx, dep)
            if fallback:
                own.append(fallback)

    e = _maybe_files_entry(FIRST_PARTY_GROUP, first_party, "first_party", RANK_FIRST_PARTY_DEPS)
    if e:
        own.append(e)
    e = _maybe_files_entry(THIRD_PARTY_GROUP, third_party, "third_party", runfiles_groups.RANK_SHARED_DEPS)
    if e:
        own.append(e)
    e = _maybe_files_entry(UNCLASSIFIED_GROUP, unclassified, "", RANK_UNCLASSIFIED)
    if e:
        own.append(e)
    return _collect_rgi(ctx, own, transitive)

def store_groups(ctx, src):
    """Relay src default runfiles / RGI. Do not emit the store payload as runfiles."""
    if not src:
        return None
    if RunfilesGroupInfo in src:
        return RunfilesGroupInfo(
            entries = src[RunfilesGroupInfo].entries,
            executable_group = None,
        )
    fallback = _fallback_runfiles_entry(ctx, src)
    if not fallback:
        return None
    return _collect_rgi(ctx, [fallback], [])

def link_groups(ctx, *, src, store_info, store_js_info, link_files):
    """Coarse npm-link decomposition using borrowed depsets plus src runfiles."""
    own = []
    e = _maybe_files_entry(
        NPM_GROUP,
        depset(transitive = [
            store_info.transitive_files,
            store_js_info.npm_sources,
        ]),
        "",
        RANK_NPM_LINKS,
    )
    if e:
        own.append(e)
    e = _maybe_files_entry(NPM_LINKS_GROUP, link_files, "", RANK_NPM_LINKS)
    if e:
        own.append(e)
    e = _maybe_files_entry(
        FIRST_PARTY_GROUP,
        store_js_info.transitive_sources,
        "first_party",
        RANK_FIRST_PARTY_DEPS,
    )
    if e:
        own.append(e)

    transitive = []
    if RunfilesGroupInfo in src:
        transitive.append(src[RunfilesGroupInfo].entries)
    else:
        fallback = _fallback_runfiles_entry(ctx, src)
        if fallback:
            own.append(fallback)
    return _collect_rgi(ctx, own, transitive)

def binary_groups(
        ctx,
        *,
        runfiles,
        executable,
        bash_launcher,
        copied_files,
        copied_originals,
        node_file,
        runtime_support_files,
        npm_wrapper_files,
        npm_sources,
        include_npm,
        coverage_bootstrap,
        coverage_report,
        lcov_merger,
        data,
        entry_point_file,
        entry_point_target):
    """Normalize the final js_binary / js_test runtime closure."""
    copy_of = _copy_map(copied_originals, copied_files)
    admitted = _flatten_files([runfiles.files] if runfiles.files else [])

    inherited_depsets = []
    npm_ds = []
    packaged_ds = []
    routing_ds = []
    source_ds = []
    store_ds = []
    first_party_inherited = []
    third_party_inherited = []
    unclassified_ds = []
    ordinary_generated = []
    app_files = []
    fallbacks = []
    extra_unclassified = []

    if executable:
        app_files.append(executable)
    if bash_launcher and bash_launcher != executable:
        app_files.append(bash_launcher)
    if entry_point_file:
        app_files.append(entry_point_file)
        original = None
        for orig, copy in copy_of.items():
            if copy == entry_point_file or orig == entry_point_file:
                original = orig
                break
        if original != None and original != entry_point_file:
            app_files.append(original)

    for dep in data:
        if RunfilesGroupInfo in dep:
            inherited_depsets.append(dep[RunfilesGroupInfo].entries)
            extra_unclassified.extend(_extra_default_outputs(dep, copy_of))
        elif JsInfo in dep or NpmPackageInfo in dep or NpmPackageStoreInfo in dep:
            # Classify through inventories at this boundary; do not wrap as a
            # foreign Label group (that would hide first/third-party roles).
            extra_unclassified.extend(_extra_default_outputs(dep, copy_of))
        elif not _is_ordinary_data(dep):
            fallback = _fallback_runfiles_entry(ctx, dep)
            if fallback:
                fallbacks.append(fallback)
        else:
            dr = dep[DefaultInfo].default_runfiles
            if dr != None and (
                _depset_has_members(dr.symlinks) or
                _depset_has_members(dr.root_symlinks) or
                _depset_has_members(dr.empty_filenames)
            ):
                fallback = _fallback_runfiles_entry(ctx, dep)
                if fallback:
                    fallbacks.append(fallback)

        if JsInfo in dep:
            jsinfo = dep[JsInfo]
            npm_ds.append(jsinfo.npm_sources)
            source_ds.append(jsinfo.sources)
            source_ds.append(jsinfo.types)
            source_ds.append(jsinfo.transitive_sources)
            source_ds.append(jsinfo.transitive_types)
        if NpmPackageStoreInfo in dep:
            store_ds.append(dep[NpmPackageStoreInfo].transitive_files)
        if NpmPackageInfo in dep and dep[NpmPackageInfo].src:
            packaged_ds.append(depset([dep[NpmPackageInfo].src]))
        if _is_ordinary_data(dep):
            for f in dep[DefaultInfo].files.to_list() if dep[DefaultInfo].files else []:
                if f.is_source:
                    app_files.append(f)
                    copy = copy_of.get(f)
                    if copy != None and copy != f:
                        app_files.append(copy)
                else:
                    ordinary_generated.append(f)
                    copy = copy_of.get(f)
                    if copy != None and copy != f:
                        ordinary_generated.append(copy)

    if lcov_merger and RunfilesGroupInfo in lcov_merger:
        inherited_depsets.append(lcov_merger[RunfilesGroupInfo].entries)

    preserved = []
    entries_list = depset(transitive = inherited_depsets).to_list() if inherited_depsets else []
    for entry in entries_list:
        name = runfiles_groups.name_str(entry.name)
        if name in _CONSUMED_NAMES:
            files = runfiles_groups.files(entry)
            if name == NPM_GROUP:
                npm_ds.append(files)
            elif name == NPM_LINKS_GROUP:
                routing_ds.append(files)
            elif name == FIRST_PARTY_GROUP:
                first_party_inherited.append(files)
            elif name == THIRD_PARTY_GROUP:
                third_party_inherited.append(files)
            else:
                unclassified_ds.append(files)
        else:
            preserved.append(_extend_with_copies(ctx, entry, copy_of, admitted))
    for fallback in fallbacks:
        preserved.append(_extend_with_copies(ctx, fallback, copy_of, admitted))

    N = _lift(_flatten_files(npm_ds + store_ds), copy_of, admitted)
    P = _lift(_flatten_files(packaged_ds + third_party_inherited), copy_of, admitted)
    L = _lift(_flatten_files(routing_ds), copy_of, admitted)
    S = _lift(_flatten_files(source_ds + first_party_inherited), copy_of, admitted)
    D = _lift(_file_dict(ordinary_generated), copy_of, admitted)

    # Routing from npm-channel symlinks is computed on pre-copy identities.
    N_pre = _flatten_files(npm_ds + store_ds)
    routing_from_shape = {}
    for f in N_pre:
        if getattr(f, "is_symlink", False):
            routing_from_shape[f] = True
    L_pre = {}
    L_pre.update(_flatten_files(routing_ds))
    L_pre.update(routing_from_shape)
    L = _lift(L_pre, copy_of, admitted)

    app = _file_dict([f for f in app_files if f in admitted])

    assigned = {}
    assigned.update(app)
    for entry in preserved:
        for f in runfiles_groups.files(entry).to_list():
            if f in admitted:
                assigned[f] = True

    own = list(preserved)
    U = _lift(_flatten_files(unclassified_ds), copy_of, admitted)

    e = _maybe_files_entry(
        ctx.label,
        [f for f in app if f in admitted],
        "first_party",
        runfiles_groups.RANK_EXECUTABLE,
        do_not_merge = True,
    )
    if e:
        own.append(e)

    if node_file and node_file in admitted:
        own.append(_native_entry(
            NODE_GROUP,
            depset([node_file]),
            "foundation",
            runfiles_groups.RANK_FOUNDATION,
        ))
        assigned[node_file] = True
    elif not node_file:
        own.append(_native_entry(
            NODE_EXTERNAL_PREFIX + runfiles_groups.name_str(ctx.label),
            depset(),
            "foundation",
            runfiles_groups.RANK_FOUNDATION,
            do_not_merge = True,
        ))

    support = [f for f in runtime_support_files if f in admitted and f not in assigned]
    e = _maybe_files_entry(
        RUNTIME_SUPPORT_GROUP,
        support,
        "foundation",
        RANK_BOOTSTRAP,
    )
    if e:
        own.append(e)
        for f in support:
            assigned[f] = True

    coverage_files = []
    if coverage_bootstrap and coverage_bootstrap in admitted and coverage_bootstrap not in assigned:
        coverage_files.append(coverage_bootstrap)
    if coverage_report and coverage_report in admitted and coverage_report not in assigned:
        coverage_files.append(coverage_report)
    e = _maybe_files_entry(COVERAGE_GROUP, coverage_files, "foundation", RANK_BOOTSTRAP)
    if e:
        own.append(e)
        for f in coverage_files:
            assigned[f] = True

    if include_npm:
        toolchain_files = [f for f in npm_wrapper_files if f in admitted and f not in assigned]
        extra_ds = []
        if npm_sources:
            extra_ds.append(npm_sources)
        toolchain = _lift(_flatten_files(extra_ds), copy_of, admitted) if extra_ds else {}
        for f in toolchain:
            if f not in assigned and f != node_file:
                toolchain_files.append(f)
        e = _maybe_files_entry(NPM_TOOLCHAIN_GROUP, toolchain_files, "foundation", RANK_BOOTSTRAP)
        if e:
            own.append(e)
            for f in toolchain_files:
                assigned[f] = True

    third_party = []
    routing = []
    first_party = []
    unclassified = []
    for f in P:
        if f in admitted and f not in assigned and f not in app:
            third_party.append(f)
            assigned[f] = True
    for f in L:
        if f in admitted and f not in assigned and f not in app:
            routing.append(f)
            assigned[f] = True
    for f in N:
        if f in admitted and f not in assigned and f not in app:
            third_party.append(f)
            assigned[f] = True
    for f in S:
        if f in admitted and f not in assigned and f not in app:
            first_party.append(f)
            assigned[f] = True
    for f in D:
        if f in admitted and f not in assigned and f not in app:
            first_party.append(f)
            assigned[f] = True
    for f in U:
        if f in admitted and f not in assigned and f not in app:
            unclassified.append(f)
            assigned[f] = True

    leftover_files = [f for f in admitted if f not in assigned]
    leftover_files.extend(unclassified)
    leftover_files.extend([f for f in extra_unclassified if f in admitted and f not in assigned])
    covered_symlinks = {}
    covered_root_symlinks = {}
    covered_empty = {}
    for entry in preserved:
        rf = runfiles_groups.runfiles(ctx, entry)
        if rf.symlinks:
            for s in rf.symlinks.to_list():
                covered_symlinks[s.path] = True
        if rf.root_symlinks:
            for s in rf.root_symlinks.to_list():
                covered_root_symlinks[s.path] = True
        if rf.empty_filenames:
            for name in rf.empty_filenames.to_list():
                covered_empty[name] = True
    leftover_symlinks = {}
    leftover_root_symlinks = {}
    leftover_empty = []
    if runfiles.symlinks:
        leftover_symlinks = {
            s.path: s.target_file
            for s in runfiles.symlinks.to_list()
            if s.path not in covered_symlinks
        }
    if runfiles.root_symlinks:
        leftover_root_symlinks = {
            s.path: s.target_file
            for s in runfiles.root_symlinks.to_list()
            if s.path not in covered_root_symlinks
        }
    if runfiles.empty_filenames:
        leftover_empty = [n for n in runfiles.empty_filenames.to_list() if n not in covered_empty]

    e = _maybe_files_entry(THIRD_PARTY_GROUP, third_party, "third_party", runfiles_groups.RANK_SHARED_DEPS)
    if e:
        own.append(e)
    e = _maybe_files_entry(NPM_LINKS_GROUP, routing, "", RANK_NPM_LINKS)
    if e:
        own.append(e)
    e = _maybe_files_entry(FIRST_PARTY_GROUP, first_party, "first_party", RANK_FIRST_PARTY_DEPS)
    if e:
        own.append(e)

    leftover_rf = None
    if leftover_files or leftover_symlinks or leftover_root_symlinks:
        if leftover_symlinks or leftover_root_symlinks:
            leftover_rf = ctx.runfiles(
                files = leftover_files,
                symlinks = leftover_symlinks,
                root_symlinks = leftover_root_symlinks,
            )
        else:
            leftover_rf = leftover_files
    if leftover_empty:
        # Bazel 7 ctx.runfiles has no empty_filenames=; wrap suppliers' runfiles.
        extra_rf = []
        for dep in data:
            dr = dep[DefaultInfo].default_runfiles
            if dr != None and _depset_has_members(dr.empty_filenames):
                extra_rf.append(dr)
        if extra_rf:
            if type(leftover_rf) == "list":
                leftover_rf = ctx.runfiles(files = leftover_rf).merge_all(extra_rf)
            elif leftover_rf != None:
                leftover_rf = leftover_rf.merge_all(extra_rf)
            else:
                leftover_rf = extra_rf[0].merge_all(extra_rf[1:]) if len(extra_rf) > 1 else extra_rf[0]
    if leftover_rf != None:
        if type(leftover_rf) == "list":
            e = _maybe_files_entry(UNCLASSIFIED_GROUP, leftover_rf, "", RANK_UNCLASSIFIED)
            if e:
                own.append(e)
        else:
            own.append(_native_entry(UNCLASSIFIED_GROUP, leftover_rf, "", RANK_UNCLASSIFIED))

    return RunfilesGroupInfo(
        entries = runfiles_groups.collect(ctx, deps = [], data = [], own = own, transitive = []),
        executable_group = ctx.label,
    )

js_runfiles_groups = struct(
    RULE_ATTRS = runfiles_groups.RULE_ATTRS,
    is_enabled = _is_enabled,
    library_groups = library_groups,
    store_groups = store_groups,
    link_groups = link_groups,
    binary_groups = binary_groups,
    AFFINITY = AFFINITY,
    FIRST_PARTY_GROUP = FIRST_PARTY_GROUP,
    THIRD_PARTY_GROUP = THIRD_PARTY_GROUP,
    NPM_GROUP = NPM_GROUP,
    NPM_LINKS_GROUP = NPM_LINKS_GROUP,
    NODE_GROUP = NODE_GROUP,
    NODE_EXTERNAL_PREFIX = NODE_EXTERNAL_PREFIX,
    RUNTIME_SUPPORT_GROUP = RUNTIME_SUPPORT_GROUP,
    NPM_TOOLCHAIN_GROUP = NPM_TOOLCHAIN_GROUP,
    COVERAGE_GROUP = COVERAGE_GROUP,
    UNCLASSIFIED_GROUP = UNCLASSIFIED_GROUP,
    RANK_FIRST_PARTY_DEPS = RANK_FIRST_PARTY_DEPS,
    RANK_NPM_LINKS = RANK_NPM_LINKS,
    RANK_UNCLASSIFIED = RANK_UNCLASSIFIED,
    RANK_BOOTSTRAP = RANK_BOOTSTRAP,
    RANK_FOUNDATION = runfiles_groups.RANK_FOUNDATION,
    RANK_SHARED_DEPS = runfiles_groups.RANK_SHARED_DEPS,
    RANK_EXECUTABLE = runfiles_groups.RANK_EXECUTABLE,
    RunfilesGroupInfo = RunfilesGroupInfo,
)
