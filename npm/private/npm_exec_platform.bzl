"""Repository rule to detect the exec platform and expose it as build flags.

This generates a repository with string_flag targets defaulting to the exec
platform's OS and CPU, plus config_setting targets for all pnpm platform
combinations. This allows generated _links_defs.bzl files to include
exec-platform select() blocks that are stable across machines.
"""

# OS values from PNPM_PLATFORMS (those with non-None bazel targets)
_PNPM_OS_VALUES = [
    "aix",
    "android",
    "darwin",
    "freebsd",
    "linux",
    "netbsd",
    "openbsd",
    "win32",
]

# CPU values from PNPM_ARCHS (those with non-None bazel targets)
_PNPM_CPU_VALUES = [
    "arm",
    "arm64",
    "ia32",
    "mips",
    "ppc",
    "ppc64",
    "riscv64",
    "s390x",
    "wasm32",
    "x64",
]

def _rctx_os_to_pnpm(os_name):
    """Map rctx.os.name to a pnpm OS string."""
    mapping = {
        "linux": "linux",
        "mac os x": "darwin",
        "windows": "win32",
        "freebsd": "freebsd",
        "openbsd": "openbsd",
    }
    return mapping.get(os_name.lower(), "linux")

def _rctx_cpu_to_pnpm(arch):
    """Map rctx.os.arch to a pnpm CPU string."""
    mapping = {
        "amd64": "x64",
        "x86_64": "x64",
        "aarch64": "arm64",
        "arm64": "arm64",
        "x86": "ia32",
        "i386": "ia32",
        "i486": "ia32",
        "i586": "ia32",
        "i686": "ia32",
    }
    return mapping.get(arch.lower(), "x64")

def _npm_exec_platform_impl(rctx):
    pnpm_os = _rctx_os_to_pnpm(rctx.os.name)
    pnpm_cpu = _rctx_cpu_to_pnpm(rctx.os.arch)

    os_values_str = "[{}]".format(", ".join(['"{}"'.format(v) for v in _PNPM_OS_VALUES]))
    cpu_values_str = "[{}]".format(", ".join(['"{}"'.format(v) for v in _PNPM_CPU_VALUES]))

    lines = [
        'load("@bazel_skylib//rules:common_settings.bzl", "string_flag")',
        "",
        "string_flag(",
        '    name = "os",',
        '    build_setting_default = "{}",'.format(pnpm_os),
        "    values = {},".format(os_values_str),
        '    visibility = ["//visibility:public"],',
        ")",
        "",
        "string_flag(",
        '    name = "cpu",',
        '    build_setting_default = "{}",'.format(pnpm_cpu),
        "    values = {},".format(cpu_values_str),
        '    visibility = ["//visibility:public"],',
        ")",
        "",
    ]

    # OS-only config_settings
    for os_val in _PNPM_OS_VALUES:
        lines += [
            "config_setting(",
            '    name = "{}",'.format(os_val),
            '    flag_values = {{":os": "{}"}},'.format(os_val),
            '    visibility = ["//visibility:public"],',
            ")",
            "",
        ]

    # CPU-only config_settings
    for cpu_val in _PNPM_CPU_VALUES:
        lines += [
            "config_setting(",
            '    name = "{}",'.format(cpu_val),
            '    flag_values = {{":cpu": "{}"}},'.format(cpu_val),
            '    visibility = ["//visibility:public"],',
            ")",
            "",
        ]

    # OS+CPU config_settings
    for os_val in _PNPM_OS_VALUES:
        for cpu_val in _PNPM_CPU_VALUES:
            lines += [
                "config_setting(",
                '    name = "{}_{}",'.format(os_val, cpu_val),
                '    flag_values = {{":os": "{}", ":cpu": "{}"}},'.format(os_val, cpu_val),
                '    visibility = ["//visibility:public"],',
                ")",
                "",
            ]

    rctx.file("BUILD.bazel", "\n".join(lines))

    # Support bazel <v8.3 by returning None if repo_metadata is not defined
    if not hasattr(rctx, "repo_metadata"):
        return None

    return rctx.repo_metadata(reproducible = False)

npm_exec_platform_detect = repository_rule(
    implementation = _npm_exec_platform_impl,
    doc = """Detects the exec platform and generates string_flag + config_setting targets.

    Used internally by rules_js to allow _links_defs.bzl files to include
    exec-platform select() conditions for optional platform-specific npm deps.
    """,
)
