"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package segfault-handler@1.3.0"

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_package_store_internal.bzl", _npm_package_store = "npm_package_store_internal")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_import.bzl",
    _npm_imported_package_store = "npm_imported_package_store",
    _npm_link_imported_package = "npm_link_imported_package",
    _npm_link_imported_package_store = "npm_link_imported_package_store")

PACKAGE = "segfault-handler"
VERSION = "1.3.0"
_ROOT_PACKAGE = ""
_PACKAGE_STORE_NAME = "segfault-handler@1.3.0"

# Generated npm_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_imported_package_store(name):
    _npm_imported_package_store(
        name = name,
        package = PACKAGE,
        version = VERSION,
        root_package = _ROOT_PACKAGE,
        deps = {
            ":.aspect_rules_js/{link_root_name}/@gar+promisify@1.1.3/pkg": "@gar/promisify",
            ":.aspect_rules_js/{link_root_name}/@npmcli+fs@2.1.2/pkg": "@npmcli/fs",
            ":.aspect_rules_js/{link_root_name}/@npmcli+move-file@2.0.1/pkg": "@npmcli/move-file",
            ":.aspect_rules_js/{link_root_name}/@tootallnate+once@2.0.0/pkg": "@tootallnate/once",
            ":.aspect_rules_js/{link_root_name}/abbrev@1.1.1/pkg": "abbrev",
            ":.aspect_rules_js/{link_root_name}/agent-base@6.0.2/pkg": "agent-base",
            ":.aspect_rules_js/{link_root_name}/agentkeepalive@4.2.1/pkg": "agentkeepalive",
            ":.aspect_rules_js/{link_root_name}/aggregate-error@3.1.0/pkg": "aggregate-error",
            ":.aspect_rules_js/{link_root_name}/ansi-regex@5.0.1/pkg": "ansi-regex",
            ":.aspect_rules_js/{link_root_name}/aproba@2.0.0/pkg": "aproba",
            ":.aspect_rules_js/{link_root_name}/are-we-there-yet@3.0.1/pkg": "are-we-there-yet",
            ":.aspect_rules_js/{link_root_name}/balanced-match@1.0.2/pkg": "balanced-match",
            ":.aspect_rules_js/{link_root_name}/bindings@1.5.0/pkg": "bindings",
            ":.aspect_rules_js/{link_root_name}/brace-expansion@1.1.11/pkg": "brace-expansion",
            ":.aspect_rules_js/{link_root_name}/brace-expansion@2.0.1/pkg": "brace-expansion",
            ":.aspect_rules_js/{link_root_name}/cacache@16.1.3/pkg": "cacache",
            ":.aspect_rules_js/{link_root_name}/chownr@2.0.0/pkg": "chownr",
            ":.aspect_rules_js/{link_root_name}/clean-stack@2.2.0/pkg": "clean-stack",
            ":.aspect_rules_js/{link_root_name}/color-support@1.1.3/pkg": "color-support",
            ":.aspect_rules_js/{link_root_name}/concat-map@0.0.1/pkg": "concat-map",
            ":.aspect_rules_js/{link_root_name}/console-control-strings@1.1.0/pkg": "console-control-strings",
            ":.aspect_rules_js/{link_root_name}/debug@4.3.4/pkg": "debug",
            ":.aspect_rules_js/{link_root_name}/delegates@1.0.0/pkg": "delegates",
            ":.aspect_rules_js/{link_root_name}/depd@1.1.2/pkg": "depd",
            ":.aspect_rules_js/{link_root_name}/emoji-regex@8.0.0/pkg": "emoji-regex",
            ":.aspect_rules_js/{link_root_name}/encoding@0.1.13/pkg": "encoding",
            ":.aspect_rules_js/{link_root_name}/env-paths@2.2.1/pkg": "env-paths",
            ":.aspect_rules_js/{link_root_name}/err-code@2.0.3/pkg": "err-code",
            ":.aspect_rules_js/{link_root_name}/file-uri-to-path@1.0.0/pkg": "file-uri-to-path",
            ":.aspect_rules_js/{link_root_name}/fs-minipass@2.1.0/pkg": "fs-minipass",
            ":.aspect_rules_js/{link_root_name}/fs.realpath@1.0.0/pkg": "fs.realpath",
            ":.aspect_rules_js/{link_root_name}/gauge@4.0.4/pkg": "gauge",
            ":.aspect_rules_js/{link_root_name}/glob@7.2.3/pkg": "glob",
            ":.aspect_rules_js/{link_root_name}/glob@8.1.0/pkg": "glob",
            ":.aspect_rules_js/{link_root_name}/graceful-fs@4.2.10/pkg": "graceful-fs",
            ":.aspect_rules_js/{link_root_name}/has-unicode@2.0.1/pkg": "has-unicode",
            ":.aspect_rules_js/{link_root_name}/http-cache-semantics@4.1.1/pkg": "http-cache-semantics",
            ":.aspect_rules_js/{link_root_name}/http-proxy-agent@5.0.0/pkg": "http-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/https-proxy-agent@5.0.1/pkg": "https-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/humanize-ms@1.2.1/pkg": "humanize-ms",
            ":.aspect_rules_js/{link_root_name}/iconv-lite@0.6.3/pkg": "iconv-lite",
            ":.aspect_rules_js/{link_root_name}/imurmurhash@0.1.4/pkg": "imurmurhash",
            ":.aspect_rules_js/{link_root_name}/indent-string@4.0.0/pkg": "indent-string",
            ":.aspect_rules_js/{link_root_name}/infer-owner@1.0.4/pkg": "infer-owner",
            ":.aspect_rules_js/{link_root_name}/inflight@1.0.6/pkg": "inflight",
            ":.aspect_rules_js/{link_root_name}/inherits@2.0.4/pkg": "inherits",
            ":.aspect_rules_js/{link_root_name}/ip@2.0.0/pkg": "ip",
            ":.aspect_rules_js/{link_root_name}/is-fullwidth-code-point@3.0.0/pkg": "is-fullwidth-code-point",
            ":.aspect_rules_js/{link_root_name}/is-lambda@1.0.1/pkg": "is-lambda",
            ":.aspect_rules_js/{link_root_name}/isexe@2.0.0/pkg": "isexe",
            ":.aspect_rules_js/{link_root_name}/lru-cache@6.0.0/pkg": "lru-cache",
            ":.aspect_rules_js/{link_root_name}/lru-cache@7.17.0/pkg": "lru-cache",
            ":.aspect_rules_js/{link_root_name}/make-fetch-happen@10.2.1/pkg": "make-fetch-happen",
            ":.aspect_rules_js/{link_root_name}/minimatch@3.1.2/pkg": "minimatch",
            ":.aspect_rules_js/{link_root_name}/minimatch@5.1.6/pkg": "minimatch",
            ":.aspect_rules_js/{link_root_name}/minipass@3.3.6/pkg": "minipass",
            ":.aspect_rules_js/{link_root_name}/minipass@4.2.4/pkg": "minipass",
            ":.aspect_rules_js/{link_root_name}/minipass-collect@1.0.2/pkg": "minipass-collect",
            ":.aspect_rules_js/{link_root_name}/minipass-fetch@2.1.2/pkg": "minipass-fetch",
            ":.aspect_rules_js/{link_root_name}/minipass-flush@1.0.5/pkg": "minipass-flush",
            ":.aspect_rules_js/{link_root_name}/minipass-pipeline@1.2.4/pkg": "minipass-pipeline",
            ":.aspect_rules_js/{link_root_name}/minipass-sized@1.0.3/pkg": "minipass-sized",
            ":.aspect_rules_js/{link_root_name}/minizlib@2.1.2/pkg": "minizlib",
            ":.aspect_rules_js/{link_root_name}/mkdirp@1.0.4/pkg": "mkdirp",
            ":.aspect_rules_js/{link_root_name}/ms@2.1.3/pkg": "ms",
            ":.aspect_rules_js/{link_root_name}/ms@2.1.2/pkg": "ms",
            ":.aspect_rules_js/{link_root_name}/nan@2.17.0/pkg": "nan",
            ":.aspect_rules_js/{link_root_name}/negotiator@0.6.3/pkg": "negotiator",
            ":.aspect_rules_js/{link_root_name}/node-gyp@9.3.1/pkg": "node-gyp",
            ":.aspect_rules_js/{link_root_name}/nopt@6.0.0/pkg": "nopt",
            ":.aspect_rules_js/{link_root_name}/npmlog@6.0.2/pkg": "npmlog",
            ":.aspect_rules_js/{link_root_name}/once@1.4.0/pkg": "once",
            ":.aspect_rules_js/{link_root_name}/p-map@4.0.0/pkg": "p-map",
            ":.aspect_rules_js/{link_root_name}/path-is-absolute@1.0.1/pkg": "path-is-absolute",
            ":.aspect_rules_js/{link_root_name}/promise-inflight@1.0.1/pkg": "promise-inflight",
            ":.aspect_rules_js/{link_root_name}/promise-retry@2.0.1/pkg": "promise-retry",
            ":.aspect_rules_js/{link_root_name}/readable-stream@3.6.1/pkg": "readable-stream",
            ":.aspect_rules_js/{link_root_name}/retry@0.12.0/pkg": "retry",
            ":.aspect_rules_js/{link_root_name}/rimraf@3.0.2/pkg": "rimraf",
            ":.aspect_rules_js/{link_root_name}/safe-buffer@5.2.1/pkg": "safe-buffer",
            ":.aspect_rules_js/{link_root_name}/safer-buffer@2.1.2/pkg": "safer-buffer",
            ":.aspect_rules_js/{link_root_name}/segfault-handler@1.3.0/pkg": "segfault-handler",
            ":.aspect_rules_js/{link_root_name}/semver@7.3.8/pkg": "semver",
            ":.aspect_rules_js/{link_root_name}/set-blocking@2.0.0/pkg": "set-blocking",
            ":.aspect_rules_js/{link_root_name}/signal-exit@3.0.7/pkg": "signal-exit",
            ":.aspect_rules_js/{link_root_name}/smart-buffer@4.2.0/pkg": "smart-buffer",
            ":.aspect_rules_js/{link_root_name}/socks@2.7.1/pkg": "socks",
            ":.aspect_rules_js/{link_root_name}/socks-proxy-agent@7.0.0/pkg": "socks-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/ssri@9.0.1/pkg": "ssri",
            ":.aspect_rules_js/{link_root_name}/string-width@4.2.3/pkg": "string-width",
            ":.aspect_rules_js/{link_root_name}/string_decoder@1.3.0/pkg": "string_decoder",
            ":.aspect_rules_js/{link_root_name}/strip-ansi@6.0.1/pkg": "strip-ansi",
            ":.aspect_rules_js/{link_root_name}/tar@6.1.13/pkg": "tar",
            ":.aspect_rules_js/{link_root_name}/unique-filename@2.0.1/pkg": "unique-filename",
            ":.aspect_rules_js/{link_root_name}/unique-slug@3.0.0/pkg": "unique-slug",
            ":.aspect_rules_js/{link_root_name}/util-deprecate@1.0.2/pkg": "util-deprecate",
            ":.aspect_rules_js/{link_root_name}/which@2.0.2/pkg": "which",
            ":.aspect_rules_js/{link_root_name}/wide-align@1.1.5/pkg": "wide-align",
            ":.aspect_rules_js/{link_root_name}/wrappy@1.0.2/pkg": "wrappy",
            ":.aspect_rules_js/{link_root_name}/yallist@4.0.0/pkg": "yallist",
        },
        ref_deps = {
            ":.aspect_rules_js/{link_root_name}/bindings@1.5.0/ref": "bindings",
            ":.aspect_rules_js/{link_root_name}/nan@2.17.0/ref": "nan",
            ":.aspect_rules_js/{link_root_name}/node-gyp@9.3.1/ref": "node-gyp",
        },
        lc_deps = {
            ":.aspect_rules_js/{link_root_name}/@gar+promisify@1.1.3/pkg": "@gar/promisify",
            ":.aspect_rules_js/{link_root_name}/@npmcli+fs@2.1.2/pkg": "@npmcli/fs",
            ":.aspect_rules_js/{link_root_name}/@npmcli+move-file@2.0.1/pkg": "@npmcli/move-file",
            ":.aspect_rules_js/{link_root_name}/@tootallnate+once@2.0.0/pkg": "@tootallnate/once",
            ":.aspect_rules_js/{link_root_name}/abbrev@1.1.1/pkg": "abbrev",
            ":.aspect_rules_js/{link_root_name}/agent-base@6.0.2/pkg": "agent-base",
            ":.aspect_rules_js/{link_root_name}/agentkeepalive@4.2.1/pkg": "agentkeepalive",
            ":.aspect_rules_js/{link_root_name}/aggregate-error@3.1.0/pkg": "aggregate-error",
            ":.aspect_rules_js/{link_root_name}/ansi-regex@5.0.1/pkg": "ansi-regex",
            ":.aspect_rules_js/{link_root_name}/aproba@2.0.0/pkg": "aproba",
            ":.aspect_rules_js/{link_root_name}/are-we-there-yet@3.0.1/pkg": "are-we-there-yet",
            ":.aspect_rules_js/{link_root_name}/balanced-match@1.0.2/pkg": "balanced-match",
            ":.aspect_rules_js/{link_root_name}/bindings@1.5.0/pkg": "bindings",
            ":.aspect_rules_js/{link_root_name}/brace-expansion@1.1.11/pkg": "brace-expansion",
            ":.aspect_rules_js/{link_root_name}/brace-expansion@2.0.1/pkg": "brace-expansion",
            ":.aspect_rules_js/{link_root_name}/cacache@16.1.3/pkg": "cacache",
            ":.aspect_rules_js/{link_root_name}/chownr@2.0.0/pkg": "chownr",
            ":.aspect_rules_js/{link_root_name}/clean-stack@2.2.0/pkg": "clean-stack",
            ":.aspect_rules_js/{link_root_name}/color-support@1.1.3/pkg": "color-support",
            ":.aspect_rules_js/{link_root_name}/concat-map@0.0.1/pkg": "concat-map",
            ":.aspect_rules_js/{link_root_name}/console-control-strings@1.1.0/pkg": "console-control-strings",
            ":.aspect_rules_js/{link_root_name}/debug@4.3.4/pkg": "debug",
            ":.aspect_rules_js/{link_root_name}/delegates@1.0.0/pkg": "delegates",
            ":.aspect_rules_js/{link_root_name}/depd@1.1.2/pkg": "depd",
            ":.aspect_rules_js/{link_root_name}/emoji-regex@8.0.0/pkg": "emoji-regex",
            ":.aspect_rules_js/{link_root_name}/encoding@0.1.13/pkg": "encoding",
            ":.aspect_rules_js/{link_root_name}/env-paths@2.2.1/pkg": "env-paths",
            ":.aspect_rules_js/{link_root_name}/err-code@2.0.3/pkg": "err-code",
            ":.aspect_rules_js/{link_root_name}/file-uri-to-path@1.0.0/pkg": "file-uri-to-path",
            ":.aspect_rules_js/{link_root_name}/fs-minipass@2.1.0/pkg": "fs-minipass",
            ":.aspect_rules_js/{link_root_name}/fs.realpath@1.0.0/pkg": "fs.realpath",
            ":.aspect_rules_js/{link_root_name}/gauge@4.0.4/pkg": "gauge",
            ":.aspect_rules_js/{link_root_name}/glob@7.2.3/pkg": "glob",
            ":.aspect_rules_js/{link_root_name}/glob@8.1.0/pkg": "glob",
            ":.aspect_rules_js/{link_root_name}/graceful-fs@4.2.10/pkg": "graceful-fs",
            ":.aspect_rules_js/{link_root_name}/has-unicode@2.0.1/pkg": "has-unicode",
            ":.aspect_rules_js/{link_root_name}/http-cache-semantics@4.1.1/pkg": "http-cache-semantics",
            ":.aspect_rules_js/{link_root_name}/http-proxy-agent@5.0.0/pkg": "http-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/https-proxy-agent@5.0.1/pkg": "https-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/humanize-ms@1.2.1/pkg": "humanize-ms",
            ":.aspect_rules_js/{link_root_name}/iconv-lite@0.6.3/pkg": "iconv-lite",
            ":.aspect_rules_js/{link_root_name}/imurmurhash@0.1.4/pkg": "imurmurhash",
            ":.aspect_rules_js/{link_root_name}/indent-string@4.0.0/pkg": "indent-string",
            ":.aspect_rules_js/{link_root_name}/infer-owner@1.0.4/pkg": "infer-owner",
            ":.aspect_rules_js/{link_root_name}/inflight@1.0.6/pkg": "inflight",
            ":.aspect_rules_js/{link_root_name}/inherits@2.0.4/pkg": "inherits",
            ":.aspect_rules_js/{link_root_name}/ip@2.0.0/pkg": "ip",
            ":.aspect_rules_js/{link_root_name}/is-fullwidth-code-point@3.0.0/pkg": "is-fullwidth-code-point",
            ":.aspect_rules_js/{link_root_name}/is-lambda@1.0.1/pkg": "is-lambda",
            ":.aspect_rules_js/{link_root_name}/isexe@2.0.0/pkg": "isexe",
            ":.aspect_rules_js/{link_root_name}/lru-cache@6.0.0/pkg": "lru-cache",
            ":.aspect_rules_js/{link_root_name}/lru-cache@7.17.0/pkg": "lru-cache",
            ":.aspect_rules_js/{link_root_name}/make-fetch-happen@10.2.1/pkg": "make-fetch-happen",
            ":.aspect_rules_js/{link_root_name}/minimatch@3.1.2/pkg": "minimatch",
            ":.aspect_rules_js/{link_root_name}/minimatch@5.1.6/pkg": "minimatch",
            ":.aspect_rules_js/{link_root_name}/minipass@3.3.6/pkg": "minipass",
            ":.aspect_rules_js/{link_root_name}/minipass@4.2.4/pkg": "minipass",
            ":.aspect_rules_js/{link_root_name}/minipass-collect@1.0.2/pkg": "minipass-collect",
            ":.aspect_rules_js/{link_root_name}/minipass-fetch@2.1.2/pkg": "minipass-fetch",
            ":.aspect_rules_js/{link_root_name}/minipass-flush@1.0.5/pkg": "minipass-flush",
            ":.aspect_rules_js/{link_root_name}/minipass-pipeline@1.2.4/pkg": "minipass-pipeline",
            ":.aspect_rules_js/{link_root_name}/minipass-sized@1.0.3/pkg": "minipass-sized",
            ":.aspect_rules_js/{link_root_name}/minizlib@2.1.2/pkg": "minizlib",
            ":.aspect_rules_js/{link_root_name}/mkdirp@1.0.4/pkg": "mkdirp",
            ":.aspect_rules_js/{link_root_name}/ms@2.1.3/pkg": "ms",
            ":.aspect_rules_js/{link_root_name}/ms@2.1.2/pkg": "ms",
            ":.aspect_rules_js/{link_root_name}/nan@2.17.0/pkg": "nan",
            ":.aspect_rules_js/{link_root_name}/negotiator@0.6.3/pkg": "negotiator",
            ":.aspect_rules_js/{link_root_name}/node-gyp@9.3.1/pkg": "node-gyp",
            ":.aspect_rules_js/{link_root_name}/nopt@6.0.0/pkg": "nopt",
            ":.aspect_rules_js/{link_root_name}/npmlog@6.0.2/pkg": "npmlog",
            ":.aspect_rules_js/{link_root_name}/once@1.4.0/pkg": "once",
            ":.aspect_rules_js/{link_root_name}/p-map@4.0.0/pkg": "p-map",
            ":.aspect_rules_js/{link_root_name}/path-is-absolute@1.0.1/pkg": "path-is-absolute",
            ":.aspect_rules_js/{link_root_name}/promise-inflight@1.0.1/pkg": "promise-inflight",
            ":.aspect_rules_js/{link_root_name}/promise-retry@2.0.1/pkg": "promise-retry",
            ":.aspect_rules_js/{link_root_name}/readable-stream@3.6.1/pkg": "readable-stream",
            ":.aspect_rules_js/{link_root_name}/retry@0.12.0/pkg": "retry",
            ":.aspect_rules_js/{link_root_name}/rimraf@3.0.2/pkg": "rimraf",
            ":.aspect_rules_js/{link_root_name}/safe-buffer@5.2.1/pkg": "safe-buffer",
            ":.aspect_rules_js/{link_root_name}/safer-buffer@2.1.2/pkg": "safer-buffer",
            ":.aspect_rules_js/{link_root_name}/segfault-handler@1.3.0/pkg_pre_lc_lite": "segfault-handler",
            ":.aspect_rules_js/{link_root_name}/semver@7.3.8/pkg": "semver",
            ":.aspect_rules_js/{link_root_name}/set-blocking@2.0.0/pkg": "set-blocking",
            ":.aspect_rules_js/{link_root_name}/signal-exit@3.0.7/pkg": "signal-exit",
            ":.aspect_rules_js/{link_root_name}/smart-buffer@4.2.0/pkg": "smart-buffer",
            ":.aspect_rules_js/{link_root_name}/socks@2.7.1/pkg": "socks",
            ":.aspect_rules_js/{link_root_name}/socks-proxy-agent@7.0.0/pkg": "socks-proxy-agent",
            ":.aspect_rules_js/{link_root_name}/ssri@9.0.1/pkg": "ssri",
            ":.aspect_rules_js/{link_root_name}/string-width@4.2.3/pkg": "string-width",
            ":.aspect_rules_js/{link_root_name}/string_decoder@1.3.0/pkg": "string_decoder",
            ":.aspect_rules_js/{link_root_name}/strip-ansi@6.0.1/pkg": "strip-ansi",
            ":.aspect_rules_js/{link_root_name}/tar@6.1.13/pkg": "tar",
            ":.aspect_rules_js/{link_root_name}/unique-filename@2.0.1/pkg": "unique-filename",
            ":.aspect_rules_js/{link_root_name}/unique-slug@3.0.0/pkg": "unique-slug",
            ":.aspect_rules_js/{link_root_name}/util-deprecate@1.0.2/pkg": "util-deprecate",
            ":.aspect_rules_js/{link_root_name}/which@2.0.2/pkg": "which",
            ":.aspect_rules_js/{link_root_name}/wide-align@1.1.5/pkg": "wide-align",
            ":.aspect_rules_js/{link_root_name}/wrappy@1.0.2/pkg": "wrappy",
            ":.aspect_rules_js/{link_root_name}/yallist@4.0.0/pkg": "yallist",
        },
        dev = False,
        has_lifecycle_build_target = True,
        transitive_closure_pattern = True,
        npm_package_target = "@@aspect_rules_js~~npm~npm__segfault-handler__1.3.0//:pkg",
        package_store_name = _PACKAGE_STORE_NAME,
        lifecycle_hooks_env = {},
        lifecycle_hooks_execution_requirements = {
            "no-sandbox": "1",
        },
        use_default_shell_env = True,
        exclude_package_contents = [],
    )

# Generated npm_package_store and npm_link_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_link_imported_package_store(name):
    return _npm_link_imported_package_store(
        name,
        package = PACKAGE,
        version = VERSION,
        root_package = _ROOT_PACKAGE,
        link_packages = {
            "": [PACKAGE],
        },
        link_visibility = ["//visibility:public"],
        bins = {},
        link = None,
        package_store_name = _PACKAGE_STORE_NAME,
        public_visibility = True,
    )

# Generated npm_package_store and npm_link_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_link_imported_package(
        name = "node_modules",
        link = None,
        fail_if_no_link = True):
    return _npm_link_imported_package(
        name,
        package = PACKAGE,
        version = VERSION,
        root_package = _ROOT_PACKAGE,
        link = link,
        link_packages = {
            "": [PACKAGE],
        },
        public_visibility = True,
        npm_link_imported_package_store_macro = npm_link_imported_package_store,
        npm_imported_package_store_macro = npm_imported_package_store,
        fail_if_no_link = fail_if_no_link,
    )
