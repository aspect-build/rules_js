"Private pnpm related platform info."

# NOTE:
#  - an entry existing in the PNPM_{ARCHS,PLATFORMS} means it is known to rules_js
#  - an entry mapping to None means it is unsupported within rules_js/bazel

# Node/PNPM architectures and correspending @platforms labels
# See https://nodejs.org/api/process.html#processarch
PNPM_ARCHS = {
    "arm64": "@platforms//cpu:arm64",
    "arm": "@platforms//cpu:arm",
    "ppc": "@platforms//cpu:ppc",  # NOTE: removed in node24
    "ppc64": "@platforms//cpu:ppc64le",
    "riscv64": "@platforms//cpu:riscv64",
    "s390x": "@platforms//cpu:s390x",
    "ia32": "@platforms//cpu:x86_32",
    "x64": "@platforms//cpu:x86_64",
    "mips": "@platforms//cpu:mips64",  # TODO: confirm

    # Additional platforms found in pnpm [cpu] fields not on Node.js docs
    "wasm32": "@platforms//cpu:wasm32",
}

PNPM_ARCH_ALIASES = {
    # Platforms that map to the same bazel constraint as other platforms
    # TODO: confirm mappings
    "mipsel": "mips",
    "loong64": None,
    "s390": "s390x",

    # Additional platform aliases found in pnpm [cpu] fields not on Node.js docs
    "mips64el": "mips",
    "x32": "ia32",
    "x86": "ia32",
}

# Node/PNPM platforms and correspending @platforms labels
# See https://nodejs.org/api/process.html#processplatform
PNPM_PLATFORMS = {
    "aix": "@platforms//os:linux",
    "darwin": "@platforms//os:macos",
    "freebsd": "@platforms//os:freebsd",
    "linux": "@platforms//os:linux",
    "openbsd": "@platforms//os:openbsd",
    "win32": "@platforms//os:windows",
    "sunos": None,  # TODO: confirm no bazel support

    # Additional platforms found in pnpm [os] fields not on Node.js docs
    "android": "@platforms//os:android",
    "netbsd": "@platforms//os:netbsd",
    "openharmony": None,  # TODO: confirm no bazel support
}
