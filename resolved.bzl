""
resolved = [
    {
        "original_rule_class": "local_repository",
        "original_attributes": {
            "name": "bazel_tools",
            "path": "/home/alexeagle/.cache/bazel/_bazel_alexeagle/install/d81761ab5244f5f4735b9254de6662ba/embedded_tools",
        },
        "native": "local_repository(name = \"bazel_tools\", path = __embedded_dir__ + \"/\" + \"embedded_tools\")",
    },
    {
        "original_rule_class": "local_config_platform",
        "original_attributes": {
            "name": "local_config_platform",
        },
        "native": "local_config_platform(name = 'local_config_platform')",
    },
    {
        "original_rule_class": "@bazel_tools//tools/sh:sh_configure.bzl%sh_config",
        "definition_information": "Repository local_config_sh instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:525:13: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/sh/sh_configure.bzl:83:14: in sh_configure\nRepository rule sh_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/sh/sh_configure.bzl:72:28: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:41:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_linux_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:57:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_linux_s390x_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:90:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_linux_ppc64le_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:73:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk16_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:257:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk17_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:359:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/jdk:local_java_repository.bzl%_local_java_repository_rule",
        "definition_information": "Repository local_jdk instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:27:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/local_java_repository.bzl:231:32: in local_java_repository\nRepository rule _local_java_repository_rule defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/local_java_repository.bzl:202:46: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk16_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:291:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk17_win_arm64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:375:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk11_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:107:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:123:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk17_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:325:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:140:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk11_win_arm64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:156:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk17_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:342:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk15_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:172:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk15_macos_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:189:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk15_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:206:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk15_win_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:223:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk17_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:308:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "definition_information": "Repository remotejdk16_macos_aarch64_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:274:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/jdk:remote_java_repository.bzl%_toolchain_config",
        "definition_information": "Repository remotejdk16_linux_toolchain_config_repo instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:240:6: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/build_defs/repo/utils.bzl:233:18: in maybe\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:53:22: in remote_java_repository\nRepository rule _toolchain_config defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/jdk/remote_java_repository.bzl:26:36: in <toplevel>\n",
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
        "original_rule_class": "@bazel_tools//tools/osx:xcode_configure.bzl%xcode_autoconf",
        "definition_information": "Repository local_config_xcode instantiated at:\n  /DEFAULT.WORKSPACE.SUFFIX:522:16: in <toplevel>\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/osx/xcode_configure.bzl:293:19: in xcode_configure\nRepository rule xcode_autoconf defined at:\n  /home/alexeagle/.cache/bazel/_bazel_alexeagle/581b2ac03dd093577e8a6ba6b6509be5/external/bazel_tools/tools/osx/xcode_configure.bzl:282:33: in <toplevel>\n",
        "original_attributes": {
            "name": "local_config_xcode",
            "generator_name": "local_config_xcode",
            "generator_function": "xcode_configure",
            "generator_location": None,
            "xcode_locator": "@bazel_tools//tools/osx:xcode_locator.m",
        },
        "repositories": [
            {
                "rule_class": "@bazel_tools//tools/osx:xcode_configure.bzl%xcode_autoconf",
                "attributes": {
                    "name": "local_config_xcode",
                    "generator_name": "local_config_xcode",
                    "generator_function": "xcode_configure",
                    "generator_location": None,
                    "xcode_locator": "@bazel_tools//tools/osx:xcode_locator.m",
                },
                "output_tree_hash": "ec026961157bb71cf68d1b568815ad68147ed16f318161bc0da40f6f3d7d79fd",
            },
        ],
    },
]
