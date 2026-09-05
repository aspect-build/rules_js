"""Runfiles-group helpers and the JsRunfilesGroupsInfo companion provider.

Grouping work is gated by `runfiles_groups.is_enabled(ctx)`. Callers must merge
`runfiles_groups.RULE_ATTRS` into the rule/aspect attrs before calling
`is_enabled`.
"""

load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:providers.bzl", "RunfilesGroupInfo")
load(":js_helpers.bzl", "js_info_selected_file_depsets", "selected_js_info_channels")
load(":js_info.bzl", "JsInfo")

# Named groups jointly supplied by multiple targets. Public convention.
NODE_GROUP = "aspect_rules_js#node"
RUNTIME_SUPPORT_GROUP = "aspect_rules_js#runtime_support"
NPM_GROUP = "aspect_rules_js#npm"
COVERAGE_GROUP = "aspect_rules_js#coverage"

_MERGE_AFFINITY = "aspect_rules_js"
_EMPTY_ENTRIES = depset()

def _js_runfiles_groups_info_init(
        *,
        default_files = None,
        sources = None,
        types = None,
        transitive_sources = None,
        transitive_types = None,
        npm_sources = None,
        store_files = None,
        transitive_store_files = None):
    return {
        "default_files": default_files if default_files != None else _EMPTY_ENTRIES,
        "sources": sources if sources != None else _EMPTY_ENTRIES,
        "types": types if types != None else _EMPTY_ENTRIES,
        "transitive_sources": transitive_sources if transitive_sources != None else _EMPTY_ENTRIES,
        "transitive_types": transitive_types if transitive_types != None else _EMPTY_ENTRIES,
        "npm_sources": npm_sources if npm_sources != None else _EMPTY_ENTRIES,
        "store_files": store_files if store_files != None else _EMPTY_ENTRIES,
        "transitive_store_files": transitive_store_files if transitive_store_files != None else _EMPTY_ENTRIES,
    }

JsRunfilesGroupsInfo, _ = provider(
    doc = """Grouping of selectable file payloads for JsInfo / store channels.

    Not a replacement for RunfilesGroupInfo. Absence is supported. Each field is a
    default-ordered depset of `runfiles_groups.entry` values whose files equal the
    corresponding existing provider field.
    """,
    init = _js_runfiles_groups_info_init,
    fields = {
        "default_files": "Entries whose files equal DefaultInfo.files.",
        "sources": "Entries whose files equal JsInfo.sources.",
        "types": "Entries whose files equal JsInfo.types.",
        "transitive_sources": "Entries whose files equal JsInfo.transitive_sources.",
        "transitive_types": "Entries whose files equal JsInfo.transitive_types.",
        "npm_sources": "Entries whose files equal JsInfo.npm_sources.",
        "store_files": "Entries whose files equal NpmPackageStoreInfo.files.",
        "transitive_store_files": "Entries whose files equal NpmPackageStoreInfo.transitive_files.",
    },
)

def _is_enabled(ctx):
    """True when grouping attrs are present and the global flag is on."""
    if not hasattr(ctx.attr, "_runfiles_group_enabled"):
        return False
    return runfiles_groups.is_enabled(ctx)

def _native_entry(name, content, kind, rank):
    """An entry with rules_js-known metadata."""
    return runfiles_groups.entry(
        name = name,
        content = content,
        kind = kind,
        rank = rank,
        do_not_merge = False,
        weight = None,
        merge_affinity = _MERGE_AFFINITY,
    )

def _maybe_files_entry(name, files, kind, rank):
    """Files-only native entry, or None when the depset/list is empty (O(1))."""
    if not files:
        return None
    if type(files) != "depset":
        files = depset(files)
    return _native_entry(name, files, kind, rank)

def _fallback_entry(name, content):
    """Foreign/unspecified metadata; follows upstream data_entry defaults."""
    return runfiles_groups.entry(name = name, content = content)

def _store_kind_and_rank(provenance):
    if provenance == "imported":
        return ("third_party", runfiles_groups.RANK_SHARED_DEPS)
    if provenance == "local":
        return ("first_party", runfiles_groups.RANK_EXECUTABLE)
    return ("", 0)

def _opaque_default_runfiles(ctx, dep):
    default_info = dep[DefaultInfo]
    runfiles = default_info.default_runfiles
    if runfiles == None:
        runfiles = ctx.runfiles()
    return runfiles

def _companion_selected_entry_depsets(companion, channels):
    entries = []
    if channels.source_field:
        entries.append(getattr(companion, channels.source_field))
    if channels.type_field:
        entries.append(getattr(companion, channels.type_field))
    if channels.npm_field:
        entries.append(companion.npm_sources)
    return entries

def _channel_entries_from_targets(targets, field, fallback_js_field, own = []):
    """Propagate one companion channel; files-only fallback for foreign JsInfo."""
    transitive = []
    direct = list(own)
    for target in targets:
        if JsRunfilesGroupsInfo in target:
            transitive.append(getattr(target[JsRunfilesGroupsInfo], field))
        elif JsInfo in target:
            files = getattr(target[JsInfo], fallback_js_field)
            if files:
                direct.append(_fallback_entry(target.label, files))
    return runfiles_groups.entries(direct = direct, transitive = transitive)

def _srcs_deps_runtime(ctx, dep):
    """Runtime entries for srcs/types/deps: RGI or opaque default_runfiles only."""
    if RunfilesGroupInfo in dep:
        return [], [dep[RunfilesGroupInfo].entries]
    return [_fallback_entry(dep.label, _opaque_default_runfiles(ctx, dep))], []

def _data_target_runtime(ctx, dep, channels):
    """Runtime + selectable contributions for a data-edge target.

    Returns (direct_entries, transitive_entry_depsets).
    """
    has_rgi = RunfilesGroupInfo in dep
    has_companion = JsRunfilesGroupsInfo in dep
    has_jsinfo = JsInfo in dep
    direct = []
    transitive = []

    if has_rgi:
        transitive.append(dep[RunfilesGroupInfo].entries)
        if has_companion:
            transitive.append(dep[JsRunfilesGroupsInfo].default_files)
        else:
            files = dep[DefaultInfo].files
            if files:
                direct.append(_fallback_entry(dep.label, files))
        if has_companion:
            transitive.extend(_companion_selected_entry_depsets(dep[JsRunfilesGroupsInfo], channels))
        elif has_jsinfo:
            selected = depset(transitive = js_info_selected_file_depsets(dep[JsInfo], channels))
            if selected:
                direct.append(_fallback_entry(dep.label, selected))
        return direct, transitive

    if has_companion:
        direct.append(_fallback_entry(dep.label, _opaque_default_runfiles(ctx, dep)))
        transitive.append(dep[JsRunfilesGroupsInfo].default_files)
        transitive.extend(_companion_selected_entry_depsets(dep[JsRunfilesGroupsInfo], channels))
        return direct, transitive

    # No providers: upstream data_entry covers files + default_runfiles. Selected
    # JsInfo files share the same fallback Label so resolve folds them.
    direct.append(runfiles_groups.data_entry(ctx, dep))
    if has_jsinfo:
        selected = depset(transitive = js_info_selected_file_depsets(dep[JsInfo], channels))
        if selected:
            direct.append(_fallback_entry(dep.label, selected))
    return direct, transitive

def _file_group_name(ctx, file, original, was_copied, producer_target):
    if was_copied:
        return ctx.label
    if producer_target != None and JsRunfilesGroupsInfo in producer_target:
        return producer_target.label
    if original.is_source:
        return original.owner
    if file.owner:
        return file.owner
    return ctx.label

def _binary_groups(
        ctx,
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
        include_sources,
        include_types,
        include_transitive_sources,
        include_transitive_types,
        include_npm_sources,
        entry_point_file,
        entry_point_target,
        entry_point_was_copied):
    """Assemble RunfilesGroupInfo for a js_binary / js_test after final runfiles."""
    own = []
    transitive = []

    support = list(runtime_support_files)
    if coverage_bootstrap:
        support.append(coverage_bootstrap)
    e = _maybe_files_entry(RUNTIME_SUPPORT_GROUP, support, "foundation", runfiles_groups.RANK_FOUNDATION)
    if e:
        own.append(e)

    if include_npm:
        # rules_nodejs defines npm_sources as [npm] + npm_srcs, and npm_srcs
        # includes :node_files. Putting that depset in the npm group would
        # overlap the node File. Keep npm_sources with the node group (same
        # Node distribution) and put only the rules_js npm wrapper in #npm.
        if node_file:
            node_content = depset([node_file], transitive = [npm_sources] if npm_sources else [])
            own.append(_native_entry(NODE_GROUP, node_content, "foundation", runfiles_groups.RANK_FOUNDATION))
            e = _maybe_files_entry(NPM_GROUP, npm_wrapper_files, "foundation", runfiles_groups.RANK_FOUNDATION)
            if e:
                own.append(e)
        else:
            content = depset(npm_wrapper_files, transitive = [npm_sources] if npm_sources else [])
            if content:
                own.append(_native_entry(NPM_GROUP, content, "foundation", runfiles_groups.RANK_FOUNDATION))
    elif node_file:
        e = _maybe_files_entry(NODE_GROUP, [node_file], "foundation", runfiles_groups.RANK_FOUNDATION)
        if e:
            own.append(e)

    binary_files = [executable]
    if bash_launcher and bash_launcher != executable:
        binary_files.append(bash_launcher)

    extra_owned = {}
    for i, f in enumerate(copied_files):
        original = copied_originals[i] if i < len(copied_originals) else f
        was_copied = original != f
        is_entry = f == entry_point_file or original == entry_point_file

        # Direct data files that were not copied are grouped via _data_target_runtime
        # (section 7.2). Assigning them by File.owner here would invent a second
        # group when data is a filegroup/alias wrapping another owner.
        if not was_copied and not is_entry:
            continue
        owner = _file_group_name(
            ctx,
            f,
            original,
            was_copied or (is_entry and entry_point_was_copied),
            entry_point_target if is_entry else None,
        )
        if owner == ctx.label:
            binary_files.append(f)
        else:
            extra = extra_owned.get(owner, [])
            extra.append(f)
            extra_owned[owner] = extra

    own.append(_native_entry(ctx.label, depset(binary_files), "first_party", runfiles_groups.RANK_EXECUTABLE))
    for owner, files in extra_owned.items():
        own.append(_native_entry(owner, depset(files), "first_party", runfiles_groups.RANK_EXECUTABLE))

    channels = selected_js_info_channels(
        include_sources = include_sources,
        include_types = include_types,
        include_transitive_sources = include_transitive_sources,
        include_transitive_types = include_transitive_types,
        include_npm_sources = include_npm_sources,
    )
    for dep in data:
        d, t = _data_target_runtime(ctx, dep, channels)
        own.extend(d)
        transitive.extend(t)

    if coverage_report:
        own.append(_native_entry(COVERAGE_GROUP, depset([coverage_report]), "debug", runfiles_groups.RANK_EXECUTABLE))

    if lcov_merger:
        if RunfilesGroupInfo in lcov_merger:
            transitive.append(lcov_merger[RunfilesGroupInfo].entries)
        else:
            own.append(_fallback_entry(lcov_merger.label, _opaque_default_runfiles(ctx, lcov_merger)))

    companion = JsRunfilesGroupsInfo(
        default_files = runfiles_groups.entries(direct = [
            _native_entry(ctx.label, depset([executable]), "first_party", runfiles_groups.RANK_EXECUTABLE),
        ]),
    )

    return RunfilesGroupInfo(
        entries = runfiles_groups.collect(ctx, deps = [], data = [], own = own, transitive = transitive),
        executable_group = ctx.label,
    ), companion

js_runfiles_groups = struct(
    RULE_ATTRS = runfiles_groups.RULE_ATTRS,
    is_enabled = _is_enabled,
    entries = runfiles_groups.entries,
    collect = runfiles_groups.collect,
    data_entry = runfiles_groups.data_entry,
    native_entry = _native_entry,
    maybe_files_entry = _maybe_files_entry,
    fallback_entry = _fallback_entry,
    store_kind_and_rank = _store_kind_and_rank,
    data_target_runtime = _data_target_runtime,
    srcs_deps_runtime = _srcs_deps_runtime,
    channel_entries_from_targets = _channel_entries_from_targets,
    binary_groups = _binary_groups,
    file_group_name = _file_group_name,
    companion_selected_entry_depsets = _companion_selected_entry_depsets,
    opaque_default_runfiles = _opaque_default_runfiles,
    NODE_GROUP = NODE_GROUP,
    RUNTIME_SUPPORT_GROUP = RUNTIME_SUPPORT_GROUP,
    NPM_GROUP = NPM_GROUP,
    COVERAGE_GROUP = COVERAGE_GROUP,
    MERGE_AFFINITY = _MERGE_AFFINITY,
    RANK_FOUNDATION = runfiles_groups.RANK_FOUNDATION,
    RANK_SHARED_DEPS = runfiles_groups.RANK_SHARED_DEPS,
    RANK_EXECUTABLE = runfiles_groups.RANK_EXECUTABLE,
    RunfilesGroupInfo = RunfilesGroupInfo,
    JsRunfilesGroupsInfo = JsRunfilesGroupsInfo,
)
