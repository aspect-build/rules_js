"Private pnpm related platform info."

# NOTE:
#  - an entry existing in the PNPM_{ARCHS,PLATFORMS} means it is known to rules_js
#  - an entry mapping to None means it is unsupported within rules_js/bazel
#  - currently this map is 1-1 with select() cases - if pnpm arch/platforms start mapping
#    to the same bazel @platforms this will need to be updated to be refactored

# Node/PNPM architectures and correspending @platforms labels
# See https://nodejs.org/api/process.html#processarch
PNPM_ARCHS = {
    "arm64": "@platforms//cpu:arm64",
    "arm": "@platforms//cpu:arm",
    "ppc64": "@platforms//cpu:ppc64le",
    "riscv64": "@platforms//cpu:riscv64",
    "s390x": "@platforms//cpu:s390x",
    "wasm32": "@platforms//cpu:wasm32",
    "ia32": "@platforms//cpu:x86_32",
    "x64": "@platforms//cpu:x86_64",
    "mips": "@platforms//cpu:mips64",  # TODO: confirm

    # TODO: must map to unique platforms
    "loong64": None,
    "mipsel": None,
    "mips64el": None,
    "s390": None,
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
    "sunos": None,  # TODO: confirm

    # Additional platforms found in pnpm [os] fields not on Node.js docs
    "android": "@platforms//os:android",
    "netbsd": "@platforms//os:netbsd",
    "openharmony": None,  # TODO: confirm
}
