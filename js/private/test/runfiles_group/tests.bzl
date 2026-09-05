"""Analysis-test declarations for js_binary runfiles groups."""

load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:runfiles_group_analysis_test.bzl", "runfiles_group_analysis_test")

_NODE = "aspect_rules_js#node"
_SUPPORT = "aspect_rules_js#runtime_support"
_NPM = "aspect_rules_js#npm"

def runfiles_group_tests():
    """Declares G-matrix and W-matrix runfiles-group analysis tests for this package."""
    _minimal = runfiles_groups.name_str(Label(":minimal"))
    _minimal_npm = runfiles_groups.name_str(Label(":minimal_npm"))
    _minimal_no_copy = runfiles_groups.name_str(Label(":minimal_no_copy"))
    _main_js = runfiles_groups.name_str(Label(":main.js"))

    runfiles_group_analysis_test(
        name = "minimal_contract_test",
        binaries = [":minimal"],
        check_disabled = True,
        expected_executable_group = _minimal,
        expected_group_count = 3,
        expected_group_names = [_NODE, _SUPPORT, _minimal],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "minimal_merge_test",
        binaries = [":minimal"],
        check_disabled = False,
        expected_executable_group = _minimal,
        expected_group_count = 2,
        expected_group_names = ["aspect_rules_js#node+runtime_support", _minimal],
        group_name_prefix = "aspect_rules_js#",
        max_groups = 2,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "rank_floor_test",
        binaries = [":minimal"],
        check_disabled = False,
        expected_executable_group = _minimal,
        expected_group_count = 2,
        expected_group_names = ["aspect_rules_js#node+runtime_support", _minimal],
        group_name_prefix = "aspect_rules_js#",
        max_groups = 1,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_cli_contract_test",
        binaries = [":minimal_npm"],
        check_disabled = False,
        expected_executable_group = _minimal_npm,
        expected_group_count = 4,
        expected_group_names = [_NODE, _NPM, _SUPPORT, _minimal_npm],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "no_copy_contract_test",
        binaries = [":minimal_no_copy"],
        check_disabled = False,
        expected_executable_group = _minimal_no_copy,
        expected_group_names = [_NODE, _SUPPORT, _main_js, _minimal_no_copy],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    _a_data = runfiles_groups.name_str(Label(":a_data"))
    _z_app = runfiles_groups.name_str(Label(":z_app"))
    runfiles_group_analysis_test(
        name = "executable_remap_test",
        binaries = [":z_app"],
        check_disabled = False,
        expected_executable_group = _a_data + "+" + _z_app,
        expected_group_names = [
            "aspect_rules_js#node+runtime_support",
            _a_data + "+" + _z_app,
        ],
        group_name_prefix = "aspect_rules_js#",
        max_groups = 2,
        overlapping_group_behavior = "error",
    )

    _generated_bin = runfiles_groups.name_str(Label(":generated_entry_bin"))
    _generated_entry = runfiles_groups.name_str(Label(":generated_entry"))
    runfiles_group_analysis_test(
        name = "generated_entry_test",
        binaries = [":generated_entry_bin"],
        check_disabled = False,
        expected_executable_group = _generated_bin,
        expected_group_names = [_NODE, _SUPPORT, _generated_entry, _generated_bin],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    _entry_and_data = runfiles_groups.name_str(Label(":entry_and_data"))
    runfiles_group_analysis_test(
        name = "entry_and_data_test",
        binaries = [":entry_and_data"],
        check_disabled = False,
        expected_executable_group = _entry_and_data,
        expected_group_names = [_NODE, _SUPPORT, _entry_and_data, _main_js],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    _library_bin = runfiles_groups.name_str(Label(":library_bin"))
    _library_bin_no = runfiles_groups.name_str(Label(":library_bin_no_jsinfo"))
    _leaf = runfiles_groups.name_str(Label(":leaf"))
    _mid_a = runfiles_groups.name_str(Label(":mid_a"))
    _mid_b = runfiles_groups.name_str(Label(":mid_b"))
    _main_js = runfiles_groups.name_str(Label(":main.js"))
    runfiles_group_analysis_test(
        name = "library_diamond_test",
        binaries = [":library_bin"],
        check_disabled = False,
        expected_executable_group = _library_bin,
        expected_group_names = [_NODE, _SUPPORT, _leaf, _library_bin, _main_js, _mid_a, _mid_b],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "library_no_jsinfo_flags_test",
        binaries = [":library_bin_no_jsinfo"],
        check_disabled = False,
        expected_executable_group = _library_bin_no,
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    _minimal_test = runfiles_groups.name_str(Label(":minimal_test_bin"))
    runfiles_group_analysis_test(
        name = "js_test_contract_test",
        binaries = [":minimal_test_bin"],
        check_disabled = False,
        expected_executable_group = _minimal_test,
        expected_group_count = 3,
        expected_group_names = [_NODE, _SUPPORT, _minimal_test],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    _isolated_default = runfiles_groups.name_str(Label(":isolated_default"))
    _isolated_none = runfiles_groups.name_str(Label(":isolated_none"))
    _isolated = runfiles_groups.name_str(Label(":isolated_jsinfo"))
    runfiles_group_analysis_test(
        name = "isolated_default_test",
        binaries = [":isolated_default"],
        check_disabled = False,
        expected_executable_group = _isolated_default,
        expected_group_names = [_NODE, _SUPPORT, _isolated_default, _isolated],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "isolated_none_test",
        binaries = [":isolated_none"],
        check_disabled = False,
        expected_executable_group = _isolated_none,
        expected_group_names = [_NODE, _SUPPORT, _isolated, _isolated_none],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    runfiles_group_analysis_test(
        name = "directory_entry_test",
        binaries = [":dir_entry_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":dir_entry_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "multi_out_test",
        binaries = [":multi_out_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":multi_out_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "foreign_rgi_test",
        binaries = [":foreign_rgi_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":foreign_rgi_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    runfiles_group_analysis_test(
        name = "npm_pkg_test",
        binaries = [":npm_pkg_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_pkg_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "alias_bin_test",
        binaries = [":alias_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":alias_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    runfiles_group_analysis_test(
        name = "nested_binary_test",
        binaries = [":nested_outer"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":nested_outer")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )

    runfiles_group_analysis_test(
        name = "entry_and_data_no_copy_test",
        binaries = [":entry_and_data_no_copy"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":entry_and_data_no_copy")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "entry_and_data_exempt_test",
        binaries = [":entry_and_data_exempt"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":entry_and_data_exempt")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "source_and_generated_data_test",
        binaries = [":source_and_generated_data"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":source_and_generated_data")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "external_no_copy_test",
        binaries = [":external_no_copy"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":external_no_copy")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "exec_data_test",
        binaries = [":exec_data_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":exec_data_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "typed_bin_test",
        binaries = [":typed_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":typed_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "json_tree_test",
        binaries = [":json_tree_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":json_tree_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "edge_lib_test",
        binaries = [":edge_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":edge_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "proto_bin_test",
        binaries = [":g15_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":g15_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_versions_test",
        binaries = [":npm_versions_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_versions_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_cycle_test",
        binaries = [":npm_cycle_bin"],
        check_disabled = True,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_cycle_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "local_npm_test",
        binaries = [":local_npm_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":local_npm_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "dev_link_test",
        binaries = [":dev_link_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":dev_link_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_link_no_sources_test",
        binaries = [":npm_link_no_sources"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_link_no_sources")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_cli_and_sources_test",
        binaries = [":npm_cli_and_sources"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_cli_and_sources")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_cli_only_test",
        binaries = [":npm_cli_only"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_cli_only")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "npm_sources_only_test",
        binaries = [":npm_sources_only"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":npm_sources_only")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "nested_npm_test",
        binaries = [":nested_outer_npm"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":nested_outer_npm")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "alias_npm_test",
        binaries = [":alias_npm_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":alias_npm_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "alias_nested_test",
        binaries = [":alias_nested_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":alias_nested_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "filegroup_test",
        binaries = [":filegroup_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":filegroup_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "foreign_symlinks_test",
        binaries = [":foreign_symlinks_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":foreign_symlinks_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "foreign_preorder_test",
        binaries = [":foreign_preorder_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":foreign_preorder_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "foreign_topo_test",
        binaries = [":foreign_topo_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":foreign_topo_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "foreign_mixed_test",
        binaries = [":foreign_mixed_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":foreign_mixed_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "dup_names_test",
        binaries = [":dup_names_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":dup_names_bin")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "testonly_bin_test",
        binaries = [":testonly_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":testonly_bin")),
        expected_group_count = 3,
        expected_group_names = [_NODE, _SUPPORT, runfiles_groups.name_str(Label(":testonly_bin"))],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "custom_grouped_contract_test",
        binaries = [":custom_grouped"],
        check_disabled = True,
        expected_executable_group = runfiles_groups.name_str(Label(":custom_grouped")),
        expected_group_count = 3,
        expected_group_names = [_NODE, _SUPPORT, runfiles_groups.name_str(Label(":custom_grouped"))],
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "isolated_nocomp_test",
        binaries = [":isolated_nocomp_default"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":isolated_nocomp_default")),
        max_groups = 100,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "protected_limit_test",
        binaries = [":protected_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":protected_bin")),
        expected_group_count = 3,
        group_name_prefix = "aspect_rules_js#",
        max_groups = 1,
        overlapping_group_behavior = "error",
    )
    runfiles_group_analysis_test(
        name = "w01_opaque_diamond_test",
        binaries = [":opaque_diamond_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":opaque_diamond_bin")),
        max_groups = 100,
        overlapping_group_behavior = "warn",
    )
    runfiles_group_analysis_test(
        name = "w02_named_outputs_test",
        binaries = [":w02_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":w02_bin")),
        max_groups = 100,
        overlapping_group_behavior = "warn",
    )
    runfiles_group_analysis_test(
        name = "w03_entry_overlap_test",
        binaries = [":w03_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":w03_bin")),
        max_groups = 100,
        overlapping_group_behavior = "warn",
    )

    # G09: all 32 include_* combinations against the isolated JsInfo fixture.
    for i in range(32):
        name = "isolated_combo_{}".format(i)
        runfiles_group_analysis_test(
            name = name + "_test",
            binaries = [":" + name],
            check_disabled = False,
            expected_executable_group = runfiles_groups.name_str(Label(":" + name)),
            max_groups = 100,
            overlapping_group_behavior = "error",
        )
