"""Stock runfiles_group_analysis_test families P1-P6."""

load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:runfiles_group_analysis_test.bzl", "runfiles_group_analysis_test")

def runfiles_group_tests():
    """Declares stock conformance tests for P1-P6."""
    _p1()
    _p2()
    _p3()
    _p4()
    _p5()
    _p6()

def _p1():
    runfiles_group_analysis_test(
        name = "p1_gate_and_exports",
        binaries = [
            ":minimal",
            ":minimal_test_bin",
            ":lib_with_data",
            ":p5_link",
            ":custom_grouped",
            ":custom_grouped_export_test",
            ":custom_lib_with_data",
            ":rebuilt_rgi",
            ":source_backed_link",
            ":.aspect_rules_js/source_backed_link",
        ],
        check_disabled = True,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )

def _p2():
    p2 = runfiles_groups.name_str(Label(":p2_bin"))
    runfiles_group_analysis_test(
        name = "p2_contract",
        binaries = [":p2_bin"],
        check_disabled = False,
        expected_executable_group = p2,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )

def _p3():
    runfiles_group_analysis_test(
        name = "p3_each_producer",
        binaries = [":p3_a", ":p3_b"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p3_aggregate_prelimit",
        binaries = [":p3_aggregate"],
        check_disabled = False,
        expected_group_count = 7,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p3_limit_seven",
        binaries = [":p3_aggregate"],
        check_disabled = False,
        expected_group_count = 7,
        overlapping_group_behavior = "ignore",
        max_groups = 1,
    )
    runfiles_group_analysis_test(
        name = "p3_affinity_max2",
        binaries = [":affinity_witness"],
        check_disabled = False,
        expected_group_count = 2,
        expected_group_names = [
            "aspect_rules_js#affinity_a+affinity_b",
            "foreign#affinity_c",
        ],
        group_name_prefix = "aspect_rules_js#",
        overlapping_group_behavior = "error",
        max_groups = 2,
    )
    runfiles_group_analysis_test(
        name = "p3_affinity_max1",
        binaries = [":affinity_witness"],
        check_disabled = False,
        expected_group_count = 1,
        overlapping_group_behavior = "error",
        max_groups = 1,
    )
    runfiles_group_analysis_test(
        name = "p3_link_limit_npm_roles",
        binaries = [":p5_link"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 1,
    )

def _p4():
    for name in [
        "p4_none",
        "p4_direct",
        "p4_trans",
        "p4_both",
        "p4_no_copy",
        "p4_generated_data",
        "p4_include_npm",
        "p4_dir_entry",
        "p4_copy_exception",
    ]:
        runfiles_group_analysis_test(
            name = name + "_contract",
            binaries = [":" + name],
            check_disabled = False,
            expected_executable_group = runfiles_groups.name_str(Label(":" + name)),
            overlapping_group_behavior = "ignore",
            max_groups = 100,
        )

def _p5():
    for name in [
        "p5_bin",
        "p5_wrapped_pkg_bin",
        "p5_lib_data_pkg_bin",
        "p5_link_as_src_bin",
        "p5_direct_pkg_bin",
        "p5_custom_npm_bin",
    ]:
        runfiles_group_analysis_test(
            name = name + "_contract",
            binaries = [":" + name],
            check_disabled = False,
            expected_executable_group = runfiles_groups.name_str(Label(":" + name)),
            overlapping_group_behavior = "ignore",
            max_groups = 100,
        )
    runfiles_group_analysis_test(
        name = "p5_link_coarse_contract",
        binaries = [":p5_link"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )

def _p6():
    runfiles_group_analysis_test(
        name = "p6_nested_contract",
        binaries = [":p6_outer"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":p6_outer")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_alias_contract",
        binaries = [":p6_alias"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":p6_outer")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_passthrough_contract",
        binaries = [":p6_passthrough_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_drop_contract",
        binaries = [":p6_drop_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_foreign_contract",
        binaries = [":p6_foreign_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_node_path_contract",
        binaries = [":p6_node_path_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_empty_filenames_contract",
        binaries = [":p6_py_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_copied_node_contract",
        binaries = [":p6_copied_node_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
