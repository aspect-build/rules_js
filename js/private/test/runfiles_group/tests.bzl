"""runfiles_group_analysis_test coverage for js_binary, js_library, and npm producers."""

load("@rules_runfiles_group//runfiles_group:lib.bzl", "runfiles_groups")
load("@rules_runfiles_group//runfiles_group:runfiles_group_analysis_test.bzl", "runfiles_group_analysis_test")

def runfiles_group_tests():
    """Declare stock analysis tests for grouping emission, roles, merge, and npm shapes."""
    _gate_and_exports()
    _binary_roles()
    _merge_and_limit()
    _include_flags()
    _npm_representation()
    _nested_and_foreign()

def _gate_and_exports():
    # Grouping is off unless --@rules_runfiles_group//runfiles_group:enabled.
    # js_binary, js_test, js_library(data), npm links, and custom producers emit
    # RunfilesGroupInfo when enabled; the same targets emit none when disabled.
    runfiles_group_analysis_test(
        name = "p1_gate_and_exports",
        binaries = [
            ":minimal",
            ":minimal_test_bin",
            ":lib_with_data",
            ":p1_outer",
            ":p1_opaque_lib",
            ":p1_foreign_outputs_lib",
            ":p1_foreign_outputs_bin",
            ":p6_empty_carrier_bin",
            ":p6_empty_mixed_bin",
            ":p4_grouped_copy_lib",
            ":p6_symlink_lib",
            ":p6_fg_lib",
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

def _binary_roles():
    # A js_binary with mixed data classifies launcher/entry/raw sources as the
    # protected application group, JsInfo sources as first_party, and npm links
    # as npm_links. Binaries must not emit the coarse #npm group.
    p2 = runfiles_groups.name_str(Label(":p2_bin"))
    runfiles_group_analysis_test(
        name = "p2_contract",
        binaries = [":p2_bin"],
        check_disabled = False,
        expected_executable_group = p2,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )

def _merge_and_limit():
    # Two binaries keep protected application groups. Shared first_party / npm /
    # node groups fold by name. runfiles_groups.limit() does not drop protected
    # groups; affinity-matched mergeable groups may collapse.
    runfiles_group_analysis_test(
        name = "p3_each_producer",
        binaries = [":p3_a", ":p3_b"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p3_aggregate_seven_groups",
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

def _include_flags():
    # include_sources / include_types / include_npm_sources and copy_data_to_bin
    # control which Files are in default_runfiles, and therefore which groups
    # the binary emits. include_npm adds #npm_toolchain.
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

def _npm_representation():
    # Classification follows the provider visible at the binary: store/link
    # payloads are third_party; wrapping npm_package in js_library(srcs) exposes
    # a generated tree and is first_party. Links emit coarse #npm.
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

def _nested_and_foreign():
    # A js_binary in data keeps its protected application group. Dropping
    # RunfilesGroupInfo falls back to DefaultInfo. Foreign groups, symlinks,
    # and Node toolchain Files are preserved as-is.
    runfiles_group_analysis_test(
        name = "p6_nested_contract",
        binaries = [":p6_carrier_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":p6_carrier_bin")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_via_deps_contract",
        binaries = [":p6_via_deps_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":p6_via_deps_bin")),
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
        name = "p6_copied_node_contract",
        binaries = [":p6_copied_node_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "p6_empty_mixed_contract",
        binaries = [":p6_empty_carrier_bin", ":p6_empty_mixed_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
