""
resolved = [
    {
        "original_rule_class": "local_repository",
        "original_attributes": {
            "name": "aspect_rules_js",
            "path": "../..",
        },
        "native": "local_repository(name = \"aspect_rules_js\", path = \"../..\")",
    },
    {
        "original_rule_class": "local_repository",
        "original_attributes": {
            "name": "bazel_tools",
            "path": "/home/alexeagle/.cache/bazel/_bazel_alexeagle/install/d81761ab5244f5f4735b9254de6662ba/embedded_tools",
        },
        "native": "local_repository(name = \"bazel_tools\", path = __embedded_dir__ + \"/\" + \"embedded_tools\")",
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository rules_nodejs instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:8:22: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/repositories.bzl:32:10: in rules_js_dependencies\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "rules_nodejs",
            "generator_name": "rules_nodejs",
            "generator_function": "rules_js_dependencies",
            "generator_location": None,
            "urls": [
                "https://github.com/bazelbuild/rules_nodejs/releases/download/5.4.2/rules_nodejs-core-5.4.2.tar.gz",
            ],
            "sha256": "26766278d815a6e2c43d2f6c9c72fde3fec8729e84138ffa4dabee47edc7702a",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://github.com/bazelbuild/rules_nodejs/releases/download/5.4.2/rules_nodejs-core-5.4.2.tar.gz",
                    ],
                    "sha256": "26766278d815a6e2c43d2f6c9c72fde3fec8729e84138ffa4dabee47edc7702a",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "rules_nodejs",
                },
                "output_tree_hash": "a74d8cb7073503007d408c0a4f2d4354ebc52bd175a642e4fa2401eba1cdbea0",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository bazel_skylib instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:8:22: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/repositories.bzl:25:10: in rules_js_dependencies\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "bazel_skylib",
            "generator_name": "bazel_skylib",
            "generator_function": "rules_js_dependencies",
            "generator_location": None,
            "urls": [
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            ],
            "sha256": "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
                    ],
                    "sha256": "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "bazel_skylib",
                },
                "output_tree_hash": "ec8087f03267ba09d29db54ca9f5a2227132cd78f8797f746c927d0fef549ac5",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository aspect_bazel_lib instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:8:22: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/repositories.bzl:39:10: in rules_js_dependencies\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "aspect_bazel_lib",
            "generator_name": "aspect_bazel_lib",
            "generator_function": "rules_js_dependencies",
            "generator_location": None,
            "url": "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v0.11.0.tar.gz",
            "sha256": "14e84b21189d857539c083df223c8ae2eb58f56beb3da3ec746db1265f689c7a",
            "strip_prefix": "bazel-lib-0.11.0",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v0.11.0.tar.gz",
                    "urls": [],
                    "sha256": "14e84b21189d857539c083df223c8ae2eb58f56beb3da3ec746db1265f689c7a",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "bazel-lib-0.11.0",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "aspect_bazel_lib",
                },
                "output_tree_hash": "499c7d73ece74cf9ea421a6f336320527804b3e1053122bef50507f539578c4c",
            },
        ],
    },
    {
        "original_rule_class": "@rules_nodejs//nodejs/private:nodejs_repo_host_os_alias.bzl%nodejs_repo_host_os_alias",
        "definition_information": "Repository nodejs_host instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:12:27: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/repositories.bzl:396:30: in nodejs_register_toolchains\nRepository rule nodejs_repo_host_os_alias defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/private/nodejs_repo_host_os_alias.bzl:44:44: in <toplevel>\n",
        "original_attributes": {
            "name": "nodejs_host",
            "generator_name": "nodejs_host",
            "generator_function": "nodejs_register_toolchains",
            "generator_location": None,
            "user_node_repository_name": "nodejs",
        },
        "repositories": [
            {
                "rule_class": "@rules_nodejs//nodejs/private:nodejs_repo_host_os_alias.bzl%nodejs_repo_host_os_alias",
                "attributes": {
                    "name": "nodejs_host",
                    "generator_name": "nodejs_host",
                    "generator_function": "nodejs_register_toolchains",
                    "generator_location": None,
                    "user_node_repository_name": "nodejs",
                },
                "output_tree_hash": "bd34eefeb7008da96690579385d97c3eec73218bae9c2bf365aaadac38f6d69d",
            },
        ],
    },
    {
        "original_rule_class": "@rules_nodejs//nodejs:repositories.bzl%node_repositories",
        "definition_information": "Repository nodejs_linux_amd64 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:12:27: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/repositories.bzl:385:26: in nodejs_register_toolchains\nRepository rule node_repositories defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/repositories.bzl:359:36: in <toplevel>\n",
        "original_attributes": {
            "name": "nodejs_linux_amd64",
            "generator_name": "nodejs_linux_amd64",
            "generator_function": "nodejs_register_toolchains",
            "generator_location": None,
            "node_version": "16.9.0",
            "platform": "linux_amd64",
        },
        "repositories": [
            {
                "rule_class": "@rules_nodejs//nodejs:repositories.bzl%node_repositories",
                "attributes": {
                    "name": "nodejs_linux_amd64",
                    "generator_name": "nodejs_linux_amd64",
                    "generator_function": "nodejs_register_toolchains",
                    "generator_location": None,
                    "node_version": "16.9.0",
                    "platform": "linux_amd64",
                },
                "output_tree_hash": "d2b5f71eadf61de4a8dbcc855aee17630cdb835d6245576cb5a42304aa17c757",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_host_alias_repo",
        "definition_information": "Repository yq instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:19:23: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/repositories.bzl:67:23: in register_yq_toolchains\nRepository rule yq_host_alias_repo defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/private/yq_toolchain.bzl:243:37: in <toplevel>\n",
        "original_attributes": {
            "name": "yq",
            "generator_name": "yq",
            "generator_function": "register_yq_toolchains",
            "generator_location": None,
        },
        "repositories": [
            {
                "rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_host_alias_repo",
                "attributes": {
                    "name": "yq",
                    "generator_name": "yq",
                    "generator_function": "register_yq_toolchains",
                    "generator_location": None,
                },
                "output_tree_hash": "ca59f4339bf71d6846c57d33599bfcadec73d981312bc1faf27b12f75afc20b9",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_platform_repo",
        "definition_information": "Repository yq_linux_amd64 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:19:23: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/repositories.bzl:59:25: in register_yq_toolchains\nRepository rule yq_platform_repo defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/private/yq_toolchain.bzl:217:35: in <toplevel>\n",
        "original_attributes": {
            "name": "yq_linux_amd64",
            "generator_name": "yq_linux_amd64",
            "generator_function": "register_yq_toolchains",
            "generator_location": None,
            "version": "4.24.5",
            "platform": "linux_amd64",
        },
        "repositories": [
            {
                "rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_platform_repo",
                "attributes": {
                    "name": "yq_linux_amd64",
                    "generator_name": "yq_linux_amd64",
                    "generator_function": "register_yq_toolchains",
                    "generator_location": None,
                    "version": "4.24.5",
                    "platform": "linux_amd64",
                },
                "output_tree_hash": "e77181fea7eac253781b9e20db3bb35a52b1b915f94622b7dba70e4184a010ce",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%translate_pnpm_lock",
        "definition_information": "Repository npm instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:25:20: in <toplevel>\nRepository rule translate_pnpm_lock defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:25:38: in <toplevel>\n",
        "original_attributes": {
            "name": "npm",
            "pnpm_lock": "//:pnpm-lock.yaml",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%translate_pnpm_lock",
                "attributes": {
                    "name": "npm",
                    "pnpm_lock": "//:pnpm-lock.yaml",
                },
                "output_tree_hash": "52a3309d4c60d9d99d30f18043c446980207aa23289098c32fa541ccfb8fa927",
            },
        ],
    },
    {
        "original_rule_class": "local_repository",
        "original_attributes": {
            "name": "rules_foo",
            "path": "./rules_foo",
        },
        "native": "local_repository(name = \"rules_foo\", path = \"./rules_foo\")",
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_c_2.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:57:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_c_2.0.0",
            "generator_name": "npm__at_aspect-test_c_2.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "transitive_closure": {
                "@aspect-test/c": [
                    "2.0.0",
                ],
            },
            "integrity": "sha512-vRuHi/8zxZ+IRGdgdX4VoMNFZrR9UqO87yQx61IGIkjgV7QcKUeu5jfvIE3Mr0WNQeMdO1JpyTx1UUpsE73iug==",
            "package": "@aspect-test/c",
            "version": "2.0.0",
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_c_2.0.0",
                    "generator_name": "npm__at_aspect-test_c_2.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "transitive_closure": {
                        "@aspect-test/c": [
                            "2.0.0",
                        ],
                    },
                    "integrity": "sha512-vRuHi/8zxZ+IRGdgdX4VoMNFZrR9UqO87yQx61IGIkjgV7QcKUeu5jfvIE3Mr0WNQeMdO1JpyTx1UUpsE73iug==",
                    "package": "@aspect-test/c",
                    "version": "2.0.0",
                    "link_package_guard": "",
                },
                "output_tree_hash": "4a3f434f2174db1f1edb1f33c0e09ceb82cc4452cceeb5c6f2c4755a36a728b0",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_b_5.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:26:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_b_5.0.0",
            "generator_name": "npm__at_aspect-test_b_5.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "@aspect-test/a": "5.0.0",
                "@aspect-test/c": "2.0.0",
                "@aspect-test/d": "2.0.0_@aspect-test+c@2.0.0",
            },
            "transitive_closure": {
                "@aspect-test/b": [
                    "5.0.0",
                ],
                "@aspect-test/a": [
                    "5.0.0",
                ],
                "@aspect-test/c": [
                    "1.0.0",
                    "2.0.0",
                ],
                "@aspect-test/d": [
                    "2.0.0_@aspect-test+c@1.0.0",
                    "2.0.0_@aspect-test+c@2.0.0",
                ],
            },
            "integrity": "sha512-MyIW6gHL3ds0BmDTOktorHLJUya5eZLGZlOxsKN2M9c3DWp+p1pBrA6KLQX1iq9BciryhpKwl82IAxP4jG52kw==",
            "package": "@aspect-test/b",
            "version": "5.0.0",
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_b_5.0.0",
                    "generator_name": "npm__at_aspect-test_b_5.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "@aspect-test/a": "5.0.0",
                        "@aspect-test/c": "2.0.0",
                        "@aspect-test/d": "2.0.0_@aspect-test+c@2.0.0",
                    },
                    "transitive_closure": {
                        "@aspect-test/b": [
                            "5.0.0",
                        ],
                        "@aspect-test/a": [
                            "5.0.0",
                        ],
                        "@aspect-test/c": [
                            "1.0.0",
                            "2.0.0",
                        ],
                        "@aspect-test/d": [
                            "2.0.0_@aspect-test+c@1.0.0",
                            "2.0.0_@aspect-test+c@2.0.0",
                        ],
                    },
                    "integrity": "sha512-MyIW6gHL3ds0BmDTOktorHLJUya5eZLGZlOxsKN2M9c3DWp+p1pBrA6KLQX1iq9BciryhpKwl82IAxP4jG52kw==",
                    "package": "@aspect-test/b",
                    "version": "5.0.0",
                    "link_package_guard": "",
                },
                "output_tree_hash": "03df8ae85111051da915544f52ad99783780180667cdfad560dc3db1165b28d5",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_d_2.0.0__at_aspect-test_c_1.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:68:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_1.0.0",
            "generator_name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_1.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "@aspect-test/c": "1.0.0",
            },
            "transitive_closure": {
                "@aspect-test/d": [
                    "2.0.0_@aspect-test+c@1.0.0",
                ],
                "@aspect-test/c": [
                    "1.0.0",
                ],
            },
            "integrity": "sha512-jndwr8pLUfn795uApTcXG/yZ5hV2At1aS/wo5BVLxqlVVgLoOETF/Dp4QOjMHE/SXkXFowz6Hao+WpmzVvAO0A==",
            "package": "@aspect-test/d",
            "version": "2.0.0_@aspect-test+c@1.0.0",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_1.0.0",
                    "generator_name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_1.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "@aspect-test/c": "1.0.0",
                    },
                    "transitive_closure": {
                        "@aspect-test/d": [
                            "2.0.0_@aspect-test+c@1.0.0",
                        ],
                        "@aspect-test/c": [
                            "1.0.0",
                        ],
                    },
                    "integrity": "sha512-jndwr8pLUfn795uApTcXG/yZ5hV2At1aS/wo5BVLxqlVVgLoOETF/Dp4QOjMHE/SXkXFowz6Hao+WpmzVvAO0A==",
                    "package": "@aspect-test/d",
                    "version": "2.0.0_@aspect-test+c@1.0.0",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "b4434c15679b3a8b55be8bbe5e9998acf6bccc103ff874adb4f9e27172e081f4",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_c_1.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:45:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_c_1.0.0",
            "generator_name": "npm__at_aspect-test_c_1.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "transitive_closure": {
                "@aspect-test/c": [
                    "1.0.0",
                ],
            },
            "integrity": "sha512-UorLD4TFr9CWFeYbUd5etaxSo201fYEFR+rSxXytfzefX41EWCBabsXhdhvXjK6v/HRuo1y1I1NiW2P3/bKJeA==",
            "package": "@aspect-test/c",
            "version": "1.0.0",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_c_1.0.0",
                    "generator_name": "npm__at_aspect-test_c_1.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "transitive_closure": {
                        "@aspect-test/c": [
                            "1.0.0",
                        ],
                    },
                    "integrity": "sha512-UorLD4TFr9CWFeYbUd5etaxSo201fYEFR+rSxXytfzefX41EWCBabsXhdhvXjK6v/HRuo1y1I1NiW2P3/bKJeA==",
                    "package": "@aspect-test/c",
                    "version": "1.0.0",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "565bac7f77ea8424eef1fba1d5e0e6fba728b4156b1d8e9ba0c96e96e1878a0b",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_a_5.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:7:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_a_5.0.0",
            "generator_name": "npm__at_aspect-test_a_5.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "@aspect-test/b": "5.0.0",
                "@aspect-test/c": "1.0.0",
                "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0",
            },
            "transitive_closure": {
                "@aspect-test/a": [
                    "5.0.0",
                ],
                "@aspect-test/b": [
                    "5.0.0",
                ],
                "@aspect-test/c": [
                    "2.0.0",
                    "1.0.0",
                ],
                "@aspect-test/d": [
                    "2.0.0_@aspect-test+c@2.0.0",
                    "2.0.0_@aspect-test+c@1.0.0",
                ],
            },
            "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
            "package": "@aspect-test/a",
            "version": "5.0.0",
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_a_5.0.0",
                    "generator_name": "npm__at_aspect-test_a_5.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "@aspect-test/b": "5.0.0",
                        "@aspect-test/c": "1.0.0",
                        "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0",
                    },
                    "transitive_closure": {
                        "@aspect-test/a": [
                            "5.0.0",
                        ],
                        "@aspect-test/b": [
                            "5.0.0",
                        ],
                        "@aspect-test/c": [
                            "2.0.0",
                            "1.0.0",
                        ],
                        "@aspect-test/d": [
                            "2.0.0_@aspect-test+c@2.0.0",
                            "2.0.0_@aspect-test+c@1.0.0",
                        ],
                    },
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                    "package": "@aspect-test/a",
                    "version": "5.0.0",
                    "link_package_guard": "",
                },
                "output_tree_hash": "a8252b53d923cabd6d2557d97bbcbf39ec7cf52712bfb2b3a370e618ff5f31c6",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__at_aspect-test_d_2.0.0__at_aspect-test_c_2.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:84:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_2.0.0",
            "generator_name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_2.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "@aspect-test/c": "2.0.0",
            },
            "transitive_closure": {
                "@aspect-test/d": [
                    "2.0.0_@aspect-test+c@2.0.0",
                ],
                "@aspect-test/c": [
                    "2.0.0",
                ],
            },
            "integrity": "sha512-jndwr8pLUfn795uApTcXG/yZ5hV2At1aS/wo5BVLxqlVVgLoOETF/Dp4QOjMHE/SXkXFowz6Hao+WpmzVvAO0A==",
            "package": "@aspect-test/d",
            "version": "2.0.0_@aspect-test+c@2.0.0",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_2.0.0",
                    "generator_name": "npm__at_aspect-test_d_2.0.0__at_aspect-test_c_2.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "@aspect-test/c": "2.0.0",
                    },
                    "transitive_closure": {
                        "@aspect-test/d": [
                            "2.0.0_@aspect-test+c@2.0.0",
                        ],
                        "@aspect-test/c": [
                            "2.0.0",
                        ],
                    },
                    "integrity": "sha512-jndwr8pLUfn795uApTcXG/yZ5hV2At1aS/wo5BVLxqlVVgLoOETF/Dp4QOjMHE/SXkXFowz6Hao+WpmzVvAO0A==",
                    "package": "@aspect-test/d",
                    "version": "2.0.0_@aspect-test+c@2.0.0",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "6d90aaf2183faf15b507312529ff74714fe59018c5529da79a1c59dc3b9ebedd",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__wordwrap_0.0.3 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:161:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__wordwrap_0.0.3",
            "generator_name": "npm__wordwrap_0.0.3",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "transitive_closure": {
                "wordwrap": [
                    "0.0.3",
                ],
            },
            "integrity": "sha1-o9XabNXAvAAI03I0u68b7WMFkQc=",
            "package": "wordwrap",
            "version": "0.0.3",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__wordwrap_0.0.3",
                    "generator_name": "npm__wordwrap_0.0.3",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "transitive_closure": {
                        "wordwrap": [
                            "0.0.3",
                        ],
                    },
                    "integrity": "sha1-o9XabNXAvAAI03I0u68b7WMFkQc=",
                    "package": "wordwrap",
                    "version": "0.0.3",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "8193da2023f4a8e4b2aa4d0639fcdb9932e2d396d1c46c0b9ffd710a35d0a1a5",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__unused_0.2.2 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:142:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__unused_0.2.2",
            "generator_name": "npm__unused_0.2.2",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "esprima": "1.0.0",
                "optimist": "0.6.0",
            },
            "transitive_closure": {
                "unused": [
                    "0.2.2",
                ],
                "esprima": [
                    "1.0.0",
                ],
                "optimist": [
                    "0.6.0",
                ],
                "minimist": [
                    "0.0.10",
                ],
                "wordwrap": [
                    "0.0.3",
                ],
            },
            "integrity": "sha1-zhJIBInz3ZPRDxt6yDzA1YQj6qA=",
            "package": "unused",
            "version": "0.2.2",
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__unused_0.2.2",
                    "generator_name": "npm__unused_0.2.2",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "esprima": "1.0.0",
                        "optimist": "0.6.0",
                    },
                    "transitive_closure": {
                        "unused": [
                            "0.2.2",
                        ],
                        "esprima": [
                            "1.0.0",
                        ],
                        "optimist": [
                            "0.6.0",
                        ],
                        "minimist": [
                            "0.0.10",
                        ],
                        "wordwrap": [
                            "0.0.3",
                        ],
                    },
                    "integrity": "sha1-zhJIBInz3ZPRDxt6yDzA1YQj6qA=",
                    "package": "unused",
                    "version": "0.2.2",
                    "link_package_guard": "",
                },
                "output_tree_hash": "864e95dc38ad58b206504e6e1a85cfe41ae74d3b220fa392cc606daa6d36face",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__optimist_0.6.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:124:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__optimist_0.6.0",
            "generator_name": "npm__optimist_0.6.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "deps": {
                "minimist": "0.0.10",
                "wordwrap": "0.0.3",
            },
            "transitive_closure": {
                "optimist": [
                    "0.6.0",
                ],
                "minimist": [
                    "0.0.10",
                ],
                "wordwrap": [
                    "0.0.3",
                ],
            },
            "integrity": "sha1-aUJIJvNAX3nxQub8PZrljU27kgA=",
            "package": "optimist",
            "version": "0.6.0",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__optimist_0.6.0",
                    "generator_name": "npm__optimist_0.6.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "deps": {
                        "minimist": "0.0.10",
                        "wordwrap": "0.0.3",
                    },
                    "transitive_closure": {
                        "optimist": [
                            "0.6.0",
                        ],
                        "minimist": [
                            "0.0.10",
                        ],
                        "wordwrap": [
                            "0.0.3",
                        ],
                    },
                    "integrity": "sha1-aUJIJvNAX3nxQub8PZrljU27kgA=",
                    "package": "optimist",
                    "version": "0.6.0",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "a8bef671fd7825ca4b031aff507788025a204201bf6ba03826d045730dcc5f06",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__minimist_0.0.10 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:112:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__minimist_0.0.10",
            "generator_name": "npm__minimist_0.0.10",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "transitive_closure": {
                "minimist": [
                    "0.0.10",
                ],
            },
            "integrity": "sha1-3j+YVD2/lggr5IrRoMfNqDYwHc8=",
            "package": "minimist",
            "version": "0.0.10",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__minimist_0.0.10",
                    "generator_name": "npm__minimist_0.0.10",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "transitive_closure": {
                        "minimist": [
                            "0.0.10",
                        ],
                    },
                    "integrity": "sha1-3j+YVD2/lggr5IrRoMfNqDYwHc8=",
                    "package": "minimist",
                    "version": "0.0.10",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "f71be99ebe58b4610b7505ab494305c521f8573d0706c540086d19d3727b846f",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
        "definition_information": "Repository npm__esprima_1.0.0 instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:32:17: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/npm/repositories.bzl:100:15: in npm_repositories\nRepository rule npm_import defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_rules_js/js/npm_import.bzl:31:29: in <toplevel>\n",
        "original_attributes": {
            "name": "npm__esprima_1.0.0",
            "generator_name": "npm__esprima_1.0.0",
            "generator_function": "npm_repositories",
            "generator_location": None,
            "transitive_closure": {
                "esprima": [
                    "1.0.0",
                ],
            },
            "integrity": "sha1-XwVxuUqH1RmbHzAqfifrGF5GaFA=",
            "package": "esprima",
            "version": "1.0.0",
            "indirect": True,
            "link_package_guard": "",
        },
        "repositories": [
            {
                "rule_class": "@aspect_rules_js//js:npm_import.bzl%npm_import",
                "attributes": {
                    "name": "npm__esprima_1.0.0",
                    "generator_name": "npm__esprima_1.0.0",
                    "generator_function": "npm_repositories",
                    "generator_location": None,
                    "transitive_closure": {
                        "esprima": [
                            "1.0.0",
                        ],
                    },
                    "integrity": "sha1-XwVxuUqH1RmbHzAqfifrGF5GaFA=",
                    "package": "esprima",
                    "version": "1.0.0",
                    "indirect": True,
                    "link_package_guard": "",
                },
                "output_tree_hash": "eeaf7b3de720713f57203b6b929aabc6edeace848857d49eca2c28a9e2df0611",
            },
        ],
    },
    {
        "original_rule_class": "local_config_platform",
        "original_attributes": {
            "name": "local_config_platform",
        },
        "native": "local_config_platform(name = 'local_config_platform')",
    },
    {
        "original_rule_class": "local_repository",
        "original_attributes": {
            "name": "platforms",
            "path": "/home/alexeagle/.cache/bazel/_bazel_alexeagle/install/d81761ab5244f5f4735b9254de6662ba/platforms",
        },
        "native": "local_repository(name = \"platforms\", path = __embedded_dir__ + \"/\" + \"platforms\")",
    },
    {
        "original_rule_class": "@bazel_tools//tools/sh:sh_configure.bzl%sh_config",
        "definition_information": "Repository local_config_sh instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:525:13: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/sh/sh_configure.bzl:83:14: in sh_configure\nRepository rule sh_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/sh/sh_configure.bzl:72:28: in <toplevel>\n",
        "original_attributes": {
            "name": "local_config_sh",
            "generator_name": "local_config_sh",
            "generator_function": "sh_configure",
            "generator_location": None,
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/sh:sh_configure.bzl%sh_config",
                "attributes": {
                    "name": "local_config_sh",
                    "generator_name": "local_config_sh",
                    "generator_function": "sh_configure",
                    "generator_location": None,
                },
                "output_tree_hash": "7bf5ba89669bcdf4526f821bc9f1f9f49409ae9c61c4e8f21c9f17e06c475127",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:123:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_macos_aarch64_toolchain_config_repo",
            "generator_name": "remotejdk11_macos_aarch64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_macos_aarch64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_macos_aarch64_toolchain_config_repo",
                    "generator_name": "remotejdk11_macos_aarch64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_macos_aarch64//:jdk\",\n)\n",
                },
                "output_tree_hash": "9335ce52c194d9fc058fe504fb35a45b6c2cf9188518c51cc305e43ee7378b9c",
            },
        ],
    },
    {
        "original_rule_class": "@rules_nodejs//nodejs/private:toolchains_repo.bzl%toolchains_repo",
        "definition_information": "Repository nodejs_toolchains instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:12:27: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/repositories.bzl:400:20: in nodejs_register_toolchains\nRepository rule toolchains_repo defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/rules_nodejs/nodejs/private/toolchains_repo.bzl:127:34: in <toplevel>\n",
        "original_attributes": {
            "name": "nodejs_toolchains",
            "generator_name": "nodejs_toolchains",
            "generator_function": "nodejs_register_toolchains",
            "generator_location": None,
            "user_node_repository_name": "nodejs",
        },
        "repositories": [
            {
                "rule_class": "@rules_nodejs//nodejs/private:toolchains_repo.bzl%toolchains_repo",
                "attributes": {
                    "name": "nodejs_toolchains",
                    "generator_name": "nodejs_toolchains",
                    "generator_function": "nodejs_register_toolchains",
                    "generator_location": None,
                    "user_node_repository_name": "nodejs",
                },
                "output_tree_hash": "8d4f67ce8de75346cd0a4fb362369a0083469c36e34314ef7dfb2c263a58cff2",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:140:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_win_toolchain_config_repo",
            "generator_name": "remotejdk11_win_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_win//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_win_toolchain_config_repo",
                    "generator_name": "remotejdk11_win_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_win//:jdk\",\n)\n",
                },
                "output_tree_hash": "7c675e21b0bcc857f7205eb90028ceeb8242a32335df8132fdf9bfcc8d4466a9",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:41:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_linux_toolchain_config_repo",
            "generator_name": "remotejdk11_linux_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_linux_toolchain_config_repo",
                    "generator_name": "remotejdk11_linux_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux//:jdk\",\n)\n",
                },
                "output_tree_hash": "0e06573f2dfcb55129ddff25782472dd4cf69169aed701ced60de9d835ec71a5",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_win_arm64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:156:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_win_arm64_toolchain_config_repo",
            "generator_name": "remotejdk11_win_arm64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:arm64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_win_arm64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_win_arm64_toolchain_config_repo",
                    "generator_name": "remotejdk11_win_arm64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:arm64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_win_arm64//:jdk\",\n)\n",
                },
                "output_tree_hash": "afad2f2341416e4b480bd08176488901789d26d819b478dcf0f5fff926914ee8",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_linux_s390x_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:90:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_linux_s390x_toolchain_config_repo",
            "generator_name": "remotejdk11_linux_s390x_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:s390x\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_s390x//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_linux_s390x_toolchain_config_repo",
                    "generator_name": "remotejdk11_linux_s390x_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:s390x\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_s390x//:jdk\",\n)\n",
                },
                "output_tree_hash": "334368111d5e0f71171386e8e651bda561bb07e1320c54585feafa33a6e385e8",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_linux_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:57:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_linux_aarch64_toolchain_config_repo",
            "generator_name": "remotejdk11_linux_aarch64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_aarch64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_linux_aarch64_toolchain_config_repo",
                    "generator_name": "remotejdk11_linux_aarch64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_aarch64//:jdk\",\n)\n",
                },
                "output_tree_hash": "20842b19bc9bf1ddddaf48e3a21889ba5cc8b8f3878509fd2fa553e46d04870b",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:107:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_macos_toolchain_config_repo",
            "generator_name": "remotejdk11_macos_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_macos//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_macos_toolchain_config_repo",
                    "generator_name": "remotejdk11_macos_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_macos//:jdk\",\n)\n",
                },
                "output_tree_hash": "c2e1b46fc39094c04ce9c82d755213ac9d8ee8939c4f869d8fe4a91e12259702",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk15_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:189:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk15_macos_toolchain_config_repo",
            "generator_name": "remotejdk15_macos_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_macos//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk15_macos_toolchain_config_repo",
                    "generator_name": "remotejdk15_macos_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_macos//:jdk\",\n)\n",
                },
                "output_tree_hash": "ce1cacf313b5baf89321849fb84043f9785e19d31a18e2f8b9df2d7d131b896a",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk15_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:172:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk15_linux_toolchain_config_repo",
            "generator_name": "remotejdk15_linux_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_linux//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk15_linux_toolchain_config_repo",
                    "generator_name": "remotejdk15_linux_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_linux//:jdk\",\n)\n",
                },
                "output_tree_hash": "2fbf86d271536009e53b1a24b5bef358e54af244f4eb057ea325ae88049f959c",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_linux_ppc64le_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:73:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_linux_ppc64le_toolchain_config_repo",
            "generator_name": "remotejdk11_linux_ppc64le_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:ppc\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_ppc64le//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk11_linux_ppc64le_toolchain_config_repo",
                    "generator_name": "remotejdk11_linux_ppc64le_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_11\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"11\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:ppc\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk11_linux_ppc64le//:jdk\",\n)\n",
                },
                "output_tree_hash": "053245fb5b36eb28476a77eb1a4dafbeac058c08021c8176941b82297cc0b9dc",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk15_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:223:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk15_win_toolchain_config_repo",
            "generator_name": "remotejdk15_win_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_win//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk15_win_toolchain_config_repo",
                    "generator_name": "remotejdk15_win_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_win//:jdk\",\n)\n",
                },
                "output_tree_hash": "2e92c21e10de0c9c8730a2c97c706ebb37dc864a54395d4f3c81e5a54efa033b",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk16_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:257:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk16_macos_toolchain_config_repo",
            "generator_name": "remotejdk16_macos_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_macos//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk16_macos_toolchain_config_repo",
                    "generator_name": "remotejdk16_macos_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_macos//:jdk\",\n)\n",
                },
                "output_tree_hash": "fd5883c3cdaa60899dc19a67dd6e8ddebc26a7cb6e3c01c24851befc112612d7",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk16_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:274:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk16_macos_aarch64_toolchain_config_repo",
            "generator_name": "remotejdk16_macos_aarch64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_macos_aarch64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk16_macos_aarch64_toolchain_config_repo",
                    "generator_name": "remotejdk16_macos_aarch64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_macos_aarch64//:jdk\",\n)\n",
                },
                "output_tree_hash": "fb0698ad442f5193bd3460cf038e56533ceaf655decbafb55c7b2389ed08850b",
            },
        ],
    },
    {
        "original_rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_toolchains_repo",
        "definition_information": "Repository yq_toolchains instantiated at:\n  /home/alexeagle/Projects/rules_js/e2e/link_js_package/WORKSPACE:19:23: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/repositories.bzl:69:23: in register_yq_toolchains\nRepository rule yq_toolchains_repo defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/aspect_bazel_lib/lib/private/yq_toolchain.bzl:181:37: in <toplevel>\n",
        "original_attributes": {
            "name": "yq_toolchains",
            "generator_name": "yq_toolchains",
            "generator_function": "register_yq_toolchains",
            "generator_location": None,
            "user_repository_name": "yq",
        },
        "repositories": [
            {
                "rule_class": "@aspect_bazel_lib//lib/private:yq_toolchain.bzl%yq_toolchains_repo",
                "attributes": {
                    "name": "yq_toolchains",
                    "generator_name": "yq_toolchains",
                    "generator_function": "register_yq_toolchains",
                    "generator_location": None,
                    "user_repository_name": "yq",
                },
                "output_tree_hash": "9b92da2c619f0cbe222e7de5d5e481c965aaec17a7fc92d44ad865f003629bdf",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:359:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk17_win_toolchain_config_repo",
            "generator_name": "remotejdk17_win_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_win//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk17_win_toolchain_config_repo",
                    "generator_name": "remotejdk17_win_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_win//:jdk\",\n)\n",
                },
                "output_tree_hash": "54ded9716915e93e14595fbae1b4e39852e67aafda1dac92d6ae6ead7cd47b36",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:342:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk17_macos_aarch64_toolchain_config_repo",
            "generator_name": "remotejdk17_macos_aarch64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_macos_aarch64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk17_macos_aarch64_toolchain_config_repo",
                    "generator_name": "remotejdk17_macos_aarch64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_macos_aarch64//:jdk\",\n)\n",
                },
                "output_tree_hash": "b5a6473ee64987065b741cf3e026eb1a6fc20fe69cbd1cebde24e7467bd1b23e",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:308:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk17_linux_toolchain_config_repo",
            "generator_name": "remotejdk17_linux_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_linux//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk17_linux_toolchain_config_repo",
                    "generator_name": "remotejdk17_linux_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_linux//:jdk\",\n)\n",
                },
                "output_tree_hash": "bfa60c03212d254afbda7cc57f00cf633a618dea43c174bd7ccc226faf2b272b",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:325:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk17_macos_toolchain_config_repo",
            "generator_name": "remotejdk17_macos_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_macos//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk17_macos_toolchain_config_repo",
                    "generator_name": "remotejdk17_macos_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_macos//:jdk\",\n)\n",
                },
                "output_tree_hash": "dc304167a73322ce5ff1ea980a2c6fe912fe84296233589b11fe6064fe4267e7",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk16_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:291:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk16_win_toolchain_config_repo",
            "generator_name": "remotejdk16_win_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_win//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk16_win_toolchain_config_repo",
                    "generator_name": "remotejdk16_win_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_win//:jdk\",\n)\n",
                },
                "output_tree_hash": "e2f4df4297bf751e1d50b43d694eb80c5c8c747e568b8e85fbddff9e66318d3d",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk16_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:240:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk16_linux_toolchain_config_repo",
            "generator_name": "remotejdk16_linux_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_linux//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk16_linux_toolchain_config_repo",
                    "generator_name": "remotejdk16_linux_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_16\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"16\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:linux\", \"@platforms//cpu:x86_64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk16_linux//:jdk\",\n)\n",
                },
                "output_tree_hash": "22a825b195ff9a98e5a869367615ab1cb9115f7967c87c502d3499a177404bba",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_win_arm64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:375:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk17_win_arm64_toolchain_config_repo",
            "generator_name": "remotejdk17_win_arm64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:arm64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_win_arm64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk17_win_arm64_toolchain_config_repo",
                    "generator_name": "remotejdk17_win_arm64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_17\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"17\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:windows\", \"@platforms//cpu:arm64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk17_win_arm64//:jdk\",\n)\n",
                },
                "output_tree_hash": "b02876231d45e2de9367fcc0f9d89739735a7ce64aecbab336d2f7be0bc923e6",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:local_java_repository.bzl%_local_java_repository_rule",
        "definition_information": "Repository local_jdk instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:27:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/local_java_repository.bzl:231:32: in local_java_repository\nRepository rule _local_java_repository_rule defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/local_java_repository.bzl:202:46: in <toplevel>\n",
        "original_attributes": {
            "name": "local_jdk",
            "generator_name": "local_jdk",
            "generator_function": "maybe",
            "generator_location": None,
            "java_home": "/home/alexeagle/.cache/bazel/_bazel_alexeagle/install/d81761ab5244f5f4735b9254de6662ba/embedded_tools/tools/jdk/nosystemjdk",
            "version": "",
            "build_file": "@bazel_tools//tools/jdk:jdk.BUILD",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:local_java_repository.bzl%_local_java_repository_rule",
                "attributes": {
                    "name": "local_jdk",
                    "generator_name": "local_jdk",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "java_home": "/home/alexeagle/.cache/bazel/_bazel_alexeagle/install/d81761ab5244f5f4735b9254de6662ba/embedded_tools/tools/jdk/nosystemjdk",
                    "version": "",
                    "build_file": "@bazel_tools//tools/jdk:jdk.BUILD",
                },
                "output_tree_hash": "ac15c00cb57c60b3736c85cbeaeec9d47ea86031bb87e7a3bf3619626c936174",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk15_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:206:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk15_macos_aarch64_toolchain_config_repo",
            "generator_name": "remotejdk15_macos_aarch64_toolchain_config_repo",
            "generator_function": "maybe",
            "generator_location": None,
            "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_macos_aarch64//:jdk\",\n)\n",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
                "attributes": {
                    "name": "remotejdk15_macos_aarch64_toolchain_config_repo",
                    "generator_name": "remotejdk15_macos_aarch64_toolchain_config_repo",
                    "generator_function": "maybe",
                    "generator_location": None,
                    "build_file": "\nconfig_setting(\n    name = \"prefix_version_setting\",\n    values = {\"java_runtime_version\": \"remotejdk_15\"},\n    visibility = [\"//visibility:private\"],\n)\nconfig_setting(\n    name = \"version_setting\",\n    values = {\"java_runtime_version\": \"15\"},\n    visibility = [\"//visibility:private\"],\n)\nalias(\n    name = \"version_or_prefix_version_setting\",\n    actual = select({\n        \":version_setting\": \":version_setting\",\n        \"//conditions:default\": \":prefix_version_setting\",\n    }),\n    visibility = [\"//visibility:private\"],\n)\ntoolchain(\n    name = \"toolchain\",\n    exec_compatible_with = [\"@platforms//os:macos\", \"@platforms//cpu:aarch64\"],\n    target_settings = [\":version_or_prefix_version_setting\"],\n    toolchain_type = \"@bazel_tools//tools/jdk:runtime_toolchain_type\",\n    toolchain = \"@remotejdk15_macos_aarch64//:jdk\",\n)\n",
                },
                "output_tree_hash": "976cbdbe2280306e163b7f005e0271dd5eb537e3757f6f8aa1800fe0d78c5b44",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/cpp:cc_configure.bzl%cc_autoconf_toolchains",
        "definition_information": "Repository local_config_cc_toolchains instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:519:13: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/cpp/cc_configure.bzl:183:27: in cc_configure\nRepository rule cc_autoconf_toolchains defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/cpp/cc_configure.bzl:79:41: in <toplevel>\n",
        "original_attributes": {
            "name": "local_config_cc_toolchains",
            "generator_name": "local_config_cc_toolchains",
            "generator_function": "cc_configure",
            "generator_location": None,
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/cpp:cc_configure.bzl%cc_autoconf_toolchains",
                "attributes": {
                    "name": "local_config_cc_toolchains",
                    "generator_name": "local_config_cc_toolchains",
                    "generator_function": "cc_configure",
                    "generator_location": None,
                },
                "output_tree_hash": "1f5225797781e52701eedc83d3881885dbf142cf22222c8ef3b38c8a4b70070e",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository remote_coverage_tools instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:3:13: in <toplevel>\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "remote_coverage_tools",
            "urls": [
                "https://mirror.bazel.build/bazel_coverage_output_generator/releases/coverage_output_generator-v2.5.zip",
            ],
            "sha256": "cd14f1cb4559e4723e63b7e7b06d09fcc3bd7ba58d03f354cdff1439bd936a7d",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/bazel_coverage_output_generator/releases/coverage_output_generator-v2.5.zip",
                    ],
                    "sha256": "cd14f1cb4559e4723e63b7e7b06d09fcc3bd7ba58d03f354cdff1439bd936a7d",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "remote_coverage_tools",
                },
                "output_tree_hash": "88c3913b5972e519f925fb67055b9f426ec8fb79a4c101d7335a4c5d708d4e01",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository rules_java instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:429:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "rules_java",
            "generator_name": "rules_java",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip",
                "https://github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip",
            ],
            "sha256": "bc81f1ba47ef5cc68ad32225c3d0e70b8c6f6077663835438da8d5733f917598",
            "strip_prefix": "rules_java-7cf3cefd652008d0a64a419c34c13bdca6c8f178",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip",
                        "https://github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip",
                    ],
                    "sha256": "bc81f1ba47ef5cc68ad32225c3d0e70b8c6f6077663835438da8d5733f917598",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "rules_java-7cf3cefd652008d0a64a419c34c13bdca6c8f178",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "rules_java",
                },
                "output_tree_hash": "00a0f1231dacff0b0cea3886200e0158c67a3600068275da14120f5434f83b5e",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/cpp:cc_configure.bzl%cc_autoconf",
        "definition_information": "Repository local_config_cc instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:519:13: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/cpp/cc_configure.bzl:184:16: in cc_configure\nRepository rule cc_autoconf defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/cpp/cc_configure.bzl:145:30: in <toplevel>\n",
        "original_attributes": {
            "name": "local_config_cc",
            "generator_name": "local_config_cc",
            "generator_function": "cc_configure",
            "generator_location": None,
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/cpp:cc_configure.bzl%cc_autoconf",
                "attributes": {
                    "name": "local_config_cc",
                    "generator_name": "local_config_cc",
                    "generator_function": "cc_configure",
                    "generator_location": None,
                },
                "output_tree_hash": "fc15a25c145d29ba3623e6621b1f9e7a8b692ffef5e90f00898937c5b3fdac73",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository rules_cc instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:440:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "rules_cc",
            "generator_name": "rules_cc",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_cc/archive/b1c40e1de81913a3c40e5948f78719c28152486d.zip",
                "https://github.com/bazelbuild/rules_cc/archive/b1c40e1de81913a3c40e5948f78719c28152486d.zip",
            ],
            "sha256": "d0c573b94a6ef20ef6ff20154a23d0efcb409fb0e1ff0979cec318dfe42f0cdd",
            "strip_prefix": "rules_cc-b1c40e1de81913a3c40e5948f78719c28152486d",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/github.com/bazelbuild/rules_cc/archive/b1c40e1de81913a3c40e5948f78719c28152486d.zip",
                        "https://github.com/bazelbuild/rules_cc/archive/b1c40e1de81913a3c40e5948f78719c28152486d.zip",
                    ],
                    "sha256": "d0c573b94a6ef20ef6ff20154a23d0efcb409fb0e1ff0979cec318dfe42f0cdd",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "rules_cc-b1c40e1de81913a3c40e5948f78719c28152486d",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "rules_cc",
                },
                "output_tree_hash": "ebae406cf36356889c349fb6113b9f88d2e8e7a175d9bb0ee7df49b0ae4a68aa",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository remote_java_tools instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:392:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "remote_java_tools",
            "generator_name": "remote_java_tools",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools-v11.6.zip",
                "https://github.com/bazelbuild/java_tools/releases/download/java_v11.6/java_tools-v11.6.zip",
            ],
            "sha256": "a7ac5922ee01e8b8fcb546ffc264ef314d0a0c679328b7fa4c432e5f54a86067",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools-v11.6.zip",
                        "https://github.com/bazelbuild/java_tools/releases/download/java_v11.6/java_tools-v11.6.zip",
                    ],
                    "sha256": "a7ac5922ee01e8b8fcb546ffc264ef314d0a0c679328b7fa4c432e5f54a86067",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "remote_java_tools",
                },
                "output_tree_hash": "26603032c022c8b3c813610eeacd92c4faa2eaca4a14841b3efad02f1ca22501",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository rules_proto instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:451:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "rules_proto",
            "generator_name": "rules_proto",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz",
                "https://github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz",
            ],
            "sha256": "8e7d59a5b12b233be5652e3d29f42fba01c7cbab09f6b3a8d0a57ed6d1e9a0da",
            "strip_prefix": "rules_proto-7e4afce6fe62dbff0a4a03450143146f9f2d7488",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz",
                        "https://github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz",
                    ],
                    "sha256": "8e7d59a5b12b233be5652e3d29f42fba01c7cbab09f6b3a8d0a57ed6d1e9a0da",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "rules_proto-7e4afce6fe62dbff0a4a03450143146f9f2d7488",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "rules_proto",
                },
                "output_tree_hash": "949d4de46aa6da1c096c0c7d833e9495fa4775950870c8d844b7dba6e0e03a97",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository remote_java_tools_linux instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:401:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "remote_java_tools_linux",
            "generator_name": "remote_java_tools_linux",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools_linux-v11.6.zip",
                "https://github.com/bazelbuild/java_tools/releases/download/java_v11.6/java_tools_linux-v11.6.zip",
            ],
            "sha256": "15da4f84a7d39cd179acf3035d9def638eea6ba89a0ed8f4e8a8e6e1d6c8e328",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools_linux-v11.6.zip",
                        "https://github.com/bazelbuild/java_tools/releases/download/java_v11.6/java_tools_linux-v11.6.zip",
                    ],
                    "sha256": "15da4f84a7d39cd179acf3035d9def638eea6ba89a0ed8f4e8a8e6e1d6c8e328",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "remote_java_tools_linux",
                },
                "output_tree_hash": "95dd1affc7f80e28cad65d9b46b8217e811b54fcd48f25d462cc0ade029f235b",
            },
        ],
    },
    {
        "original_rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
        "definition_information": "Repository remotejdk11_linux instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:41:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/jdk/remote_java_repository.bzl:48:17: in remote_java_repository\nRepository rule http_archive defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/70a8be737b83a91f8b132ea8989807f8/external/bazel_tools/tools/build_defs/repo/http.bzl:353:31: in <toplevel>\n",
        "original_attributes": {
            "name": "remotejdk11_linux",
            "generator_name": "remotejdk11_linux",
            "generator_function": "maybe",
            "generator_location": None,
            "urls": [
                "https://mirror.bazel.build/openjdk/azul-zulu11.50.19-ca-jdk11.0.12/zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz",
            ],
            "sha256": "b8e8a63b79bc312aa90f3558edbea59e71495ef1a9c340e38900dd28a1c579f3",
            "strip_prefix": "zulu11.50.19-ca-jdk11.0.12-linux_x64",
            "build_file": "@bazel_tools//tools/jdk:jdk.BUILD",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/build_defs/repo:http.bzl%http_archive",
                "attributes": {
                    "url": "",
                    "urls": [
                        "https://mirror.bazel.build/openjdk/azul-zulu11.50.19-ca-jdk11.0.12/zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz",
                    ],
                    "sha256": "b8e8a63b79bc312aa90f3558edbea59e71495ef1a9c340e38900dd28a1c579f3",
                    "integrity": "",
                    "netrc": "",
                    "auth_patterns": {},
                    "canonical_id": "",
                    "strip_prefix": "zulu11.50.19-ca-jdk11.0.12-linux_x64",
                    "type": "",
                    "patches": [],
                    "remote_patches": {},
                    "remote_patch_strip": 0,
                    "patch_tool": "",
                    "patch_args": [
                        "-p0",
                    ],
                    "patch_cmds": [],
                    "patch_cmds_win": [],
                    "build_file": "@bazel_tools//tools/jdk:jdk.BUILD",
                    "build_file_content": "",
                    "workspace_file_content": "",
                    "name": "remotejdk11_linux",
                },
                "output_tree_hash": "25edda442f05d2c1380a336b283fcc67ff68a9f34f919fd5f71553d63b4b5c7d",
            },
        ],
    },
]
