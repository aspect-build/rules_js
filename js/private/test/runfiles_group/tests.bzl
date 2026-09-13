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
        name = "gate_and_exports",
        binaries = [
            ":minimal",
            ":minimal_test_bin",
            ":lib_with_data",
            ":nested_lib_outer",
            ":opaque_jsinfo_lib",
            ":foreign_outputs_lib",
            ":foreign_outputs_bin",
            ":extra_symlink_carrier_bin",
            ":extra_symlink_mixed_bin",
            ":extra_symlink_outer",
            ":extra_symlink_npm_bin",
            ":grouped_copy_lib",
            ":symlink_lib",
            ":filegroup_lib",
            ":npm_link",
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
    p2 = runfiles_groups.name_str(Label(":binary_roles_bin"))
    runfiles_group_analysis_test(
        name = "binary_roles_contract",
        binaries = [":binary_roles_bin"],
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
        name = "each_producer",
        binaries = [":merge_bin_a", ":merge_bin_b"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "aggregate_seven_groups",
        binaries = [":aggregate"],
        check_disabled = False,
        expected_group_count = 7,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "limit_seven",
        binaries = [":aggregate"],
        check_disabled = False,
        expected_group_count = 7,
        overlapping_group_behavior = "ignore",
        max_groups = 1,
    )
    runfiles_group_analysis_test(
        name = "affinity_max2",
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
        name = "affinity_max1",
        binaries = [":affinity_witness"],
        check_disabled = False,
        expected_group_count = 1,
        overlapping_group_behavior = "error",
        max_groups = 1,
    )
    runfiles_group_analysis_test(
        name = "link_limit_npm_roles",
        binaries = [":npm_link"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 1,
    )

def _include_flags():
    # include_sources / include_types / include_npm_sources and copy_data_to_bin
    # control which Files are in default_runfiles, and therefore which groups
    # the binary emits. include_npm adds #npm_toolchain.
    for name in [
        "include_none",
        "include_direct",
        "include_transitive",
        "include_both",
        "no_copy",
        "generated_data_bin",
        "include_npm",
        "directory_entry_bin",
        "copy_exception",
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
        "npm_link_bin",
        "wrapped_pkg_bin",
        "lib_data_pkg_bin",
        "npm_link_as_src_bin",
        "direct_pkg_bin",
        "custom_npm_bin",
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
        name = "npm_link_coarse_contract",
        binaries = [":npm_link"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )

def _nested_and_foreign():
    # A js_binary in data keeps its protected application group. Dropping
    # RunfilesGroupInfo falls back to DefaultInfo. Foreign groups, symlinks,
    # and Node toolchain Files are preserved as-is.
    runfiles_group_analysis_test(
        name = "nested_rgi_contract",
        binaries = [":nested_rgi_carrier_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":nested_rgi_carrier_bin")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "nested_via_deps_contract",
        binaries = [":nested_via_deps_bin"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":nested_via_deps_bin")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "nested_rgi_alias_contract",
        binaries = [":nested_rgi_alias"],
        check_disabled = False,
        expected_executable_group = runfiles_groups.name_str(Label(":nested_rgi_outer")),
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "rgi_passthrough_dep_contract",
        binaries = [":rgi_passthrough_dep_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "rgi_drop_dep_contract",
        binaries = [":rgi_drop_dep_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "foreign_rgi_dep_contract",
        binaries = [":foreign_rgi_dep_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "node_path_contract",
        binaries = [":node_path_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "copied_node_contract",
        binaries = [":copied_node_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "independent_alias_identity_contract",
        binaries = [":independent_alias_identity_bin"],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
    runfiles_group_analysis_test(
        name = "extra_symlink_mixed_contract",
        binaries = [
            ":extra_symlink_carrier_bin",
            ":extra_symlink_mixed_bin",
            ":extra_symlink_inner",
            ":extra_symlink_outer",
            ":extra_symlink_nested_aggregate",
            ":extra_symlink_npm_bin",
        ],
        check_disabled = False,
        overlapping_group_behavior = "ignore",
        max_groups = 100,
    )
