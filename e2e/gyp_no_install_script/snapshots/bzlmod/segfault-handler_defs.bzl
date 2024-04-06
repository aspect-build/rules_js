"@generated by @aspect_rules_js//npm/private:npm_import.bzl for npm package segfault-handler@1.3.0"

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_package_store_internal.bzl", _npm_package_store = "npm_package_store_internal")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_link_package_store.bzl", _npm_link_package_store = "npm_link_package_store")
load("@aspect_rules_js//js:defs.bzl", _js_run_binary = "js_run_binary")

# buildifier: disable=bzl-visibility
load("@aspect_rules_js//npm/private:npm_package_internal.bzl", _npm_package_internal = "npm_package_internal")

# Generated npm_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_imported_package_store(name):
    root_package = ""
    is_root = native.package_name() == root_package
    if not is_root:
        msg = "No store links in bazel package '%s' for npm package npm package segfault-handler@1.3.0. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)
    if not name.endswith("/segfault-handler"):
        msg = "name must end with one of '/segfault-handler' when linking the store in package 'segfault-handler'; recommended value is 'node_modules/segfault-handler'"
        fail(msg)
    link_root_name = name[:-len("/segfault-handler")]

    deps = {
        ":.aspect_rules_js/{}/@gar+promisify@1.1.3/pkg".format(link_root_name): "@gar/promisify",
        ":.aspect_rules_js/{}/@npmcli+fs@2.1.2/pkg".format(link_root_name): "@npmcli/fs",
        ":.aspect_rules_js/{}/@npmcli+move-file@2.0.1/pkg".format(link_root_name): "@npmcli/move-file",
        ":.aspect_rules_js/{}/@tootallnate+once@2.0.0/pkg".format(link_root_name): "@tootallnate/once",
        ":.aspect_rules_js/{}/abbrev@1.1.1/pkg".format(link_root_name): "abbrev",
        ":.aspect_rules_js/{}/agent-base@6.0.2/pkg".format(link_root_name): "agent-base",
        ":.aspect_rules_js/{}/agentkeepalive@4.2.1/pkg".format(link_root_name): "agentkeepalive",
        ":.aspect_rules_js/{}/aggregate-error@3.1.0/pkg".format(link_root_name): "aggregate-error",
        ":.aspect_rules_js/{}/ansi-regex@5.0.1/pkg".format(link_root_name): "ansi-regex",
        ":.aspect_rules_js/{}/aproba@2.0.0/pkg".format(link_root_name): "aproba",
        ":.aspect_rules_js/{}/are-we-there-yet@3.0.1/pkg".format(link_root_name): "are-we-there-yet",
        ":.aspect_rules_js/{}/balanced-match@1.0.2/pkg".format(link_root_name): "balanced-match",
        ":.aspect_rules_js/{}/bindings@1.5.0/pkg".format(link_root_name): "bindings",
        ":.aspect_rules_js/{}/brace-expansion@1.1.11/pkg".format(link_root_name): "brace-expansion",
        ":.aspect_rules_js/{}/brace-expansion@2.0.1/pkg".format(link_root_name): "brace-expansion",
        ":.aspect_rules_js/{}/cacache@16.1.3/pkg".format(link_root_name): "cacache",
        ":.aspect_rules_js/{}/chownr@2.0.0/pkg".format(link_root_name): "chownr",
        ":.aspect_rules_js/{}/clean-stack@2.2.0/pkg".format(link_root_name): "clean-stack",
        ":.aspect_rules_js/{}/color-support@1.1.3/pkg".format(link_root_name): "color-support",
        ":.aspect_rules_js/{}/concat-map@0.0.1/pkg".format(link_root_name): "concat-map",
        ":.aspect_rules_js/{}/console-control-strings@1.1.0/pkg".format(link_root_name): "console-control-strings",
        ":.aspect_rules_js/{}/debug@4.3.4/pkg".format(link_root_name): "debug",
        ":.aspect_rules_js/{}/delegates@1.0.0/pkg".format(link_root_name): "delegates",
        ":.aspect_rules_js/{}/depd@1.1.2/pkg".format(link_root_name): "depd",
        ":.aspect_rules_js/{}/emoji-regex@8.0.0/pkg".format(link_root_name): "emoji-regex",
        ":.aspect_rules_js/{}/encoding@0.1.13/pkg".format(link_root_name): "encoding",
        ":.aspect_rules_js/{}/env-paths@2.2.1/pkg".format(link_root_name): "env-paths",
        ":.aspect_rules_js/{}/err-code@2.0.3/pkg".format(link_root_name): "err-code",
        ":.aspect_rules_js/{}/file-uri-to-path@1.0.0/pkg".format(link_root_name): "file-uri-to-path",
        ":.aspect_rules_js/{}/fs-minipass@2.1.0/pkg".format(link_root_name): "fs-minipass",
        ":.aspect_rules_js/{}/fs.realpath@1.0.0/pkg".format(link_root_name): "fs.realpath",
        ":.aspect_rules_js/{}/gauge@4.0.4/pkg".format(link_root_name): "gauge",
        ":.aspect_rules_js/{}/glob@7.2.3/pkg".format(link_root_name): "glob",
        ":.aspect_rules_js/{}/glob@8.1.0/pkg".format(link_root_name): "glob",
        ":.aspect_rules_js/{}/graceful-fs@4.2.10/pkg".format(link_root_name): "graceful-fs",
        ":.aspect_rules_js/{}/has-unicode@2.0.1/pkg".format(link_root_name): "has-unicode",
        ":.aspect_rules_js/{}/http-cache-semantics@4.1.1/pkg".format(link_root_name): "http-cache-semantics",
        ":.aspect_rules_js/{}/http-proxy-agent@5.0.0/pkg".format(link_root_name): "http-proxy-agent",
        ":.aspect_rules_js/{}/https-proxy-agent@5.0.1/pkg".format(link_root_name): "https-proxy-agent",
        ":.aspect_rules_js/{}/humanize-ms@1.2.1/pkg".format(link_root_name): "humanize-ms",
        ":.aspect_rules_js/{}/iconv-lite@0.6.3/pkg".format(link_root_name): "iconv-lite",
        ":.aspect_rules_js/{}/imurmurhash@0.1.4/pkg".format(link_root_name): "imurmurhash",
        ":.aspect_rules_js/{}/indent-string@4.0.0/pkg".format(link_root_name): "indent-string",
        ":.aspect_rules_js/{}/infer-owner@1.0.4/pkg".format(link_root_name): "infer-owner",
        ":.aspect_rules_js/{}/inflight@1.0.6/pkg".format(link_root_name): "inflight",
        ":.aspect_rules_js/{}/inherits@2.0.4/pkg".format(link_root_name): "inherits",
        ":.aspect_rules_js/{}/ip@2.0.0/pkg".format(link_root_name): "ip",
        ":.aspect_rules_js/{}/is-fullwidth-code-point@3.0.0/pkg".format(link_root_name): "is-fullwidth-code-point",
        ":.aspect_rules_js/{}/is-lambda@1.0.1/pkg".format(link_root_name): "is-lambda",
        ":.aspect_rules_js/{}/isexe@2.0.0/pkg".format(link_root_name): "isexe",
        ":.aspect_rules_js/{}/lru-cache@6.0.0/pkg".format(link_root_name): "lru-cache",
        ":.aspect_rules_js/{}/lru-cache@7.17.0/pkg".format(link_root_name): "lru-cache",
        ":.aspect_rules_js/{}/make-fetch-happen@10.2.1/pkg".format(link_root_name): "make-fetch-happen",
        ":.aspect_rules_js/{}/minimatch@3.1.2/pkg".format(link_root_name): "minimatch",
        ":.aspect_rules_js/{}/minimatch@5.1.6/pkg".format(link_root_name): "minimatch",
        ":.aspect_rules_js/{}/minipass@3.3.6/pkg".format(link_root_name): "minipass",
        ":.aspect_rules_js/{}/minipass@4.2.4/pkg".format(link_root_name): "minipass",
        ":.aspect_rules_js/{}/minipass-collect@1.0.2/pkg".format(link_root_name): "minipass-collect",
        ":.aspect_rules_js/{}/minipass-fetch@2.1.2/pkg".format(link_root_name): "minipass-fetch",
        ":.aspect_rules_js/{}/minipass-flush@1.0.5/pkg".format(link_root_name): "minipass-flush",
        ":.aspect_rules_js/{}/minipass-pipeline@1.2.4/pkg".format(link_root_name): "minipass-pipeline",
        ":.aspect_rules_js/{}/minipass-sized@1.0.3/pkg".format(link_root_name): "minipass-sized",
        ":.aspect_rules_js/{}/minizlib@2.1.2/pkg".format(link_root_name): "minizlib",
        ":.aspect_rules_js/{}/mkdirp@1.0.4/pkg".format(link_root_name): "mkdirp",
        ":.aspect_rules_js/{}/ms@2.1.2/pkg".format(link_root_name): "ms",
        ":.aspect_rules_js/{}/ms@2.1.3/pkg".format(link_root_name): "ms",
        ":.aspect_rules_js/{}/nan@2.17.0/pkg".format(link_root_name): "nan",
        ":.aspect_rules_js/{}/negotiator@0.6.3/pkg".format(link_root_name): "negotiator",
        ":.aspect_rules_js/{}/node-gyp@9.3.1/pkg".format(link_root_name): "node-gyp",
        ":.aspect_rules_js/{}/nopt@6.0.0/pkg".format(link_root_name): "nopt",
        ":.aspect_rules_js/{}/npmlog@6.0.2/pkg".format(link_root_name): "npmlog",
        ":.aspect_rules_js/{}/once@1.4.0/pkg".format(link_root_name): "once",
        ":.aspect_rules_js/{}/p-map@4.0.0/pkg".format(link_root_name): "p-map",
        ":.aspect_rules_js/{}/path-is-absolute@1.0.1/pkg".format(link_root_name): "path-is-absolute",
        ":.aspect_rules_js/{}/promise-inflight@1.0.1/pkg".format(link_root_name): "promise-inflight",
        ":.aspect_rules_js/{}/promise-retry@2.0.1/pkg".format(link_root_name): "promise-retry",
        ":.aspect_rules_js/{}/readable-stream@3.6.1/pkg".format(link_root_name): "readable-stream",
        ":.aspect_rules_js/{}/retry@0.12.0/pkg".format(link_root_name): "retry",
        ":.aspect_rules_js/{}/rimraf@3.0.2/pkg".format(link_root_name): "rimraf",
        ":.aspect_rules_js/{}/safe-buffer@5.2.1/pkg".format(link_root_name): "safe-buffer",
        ":.aspect_rules_js/{}/safer-buffer@2.1.2/pkg".format(link_root_name): "safer-buffer",
        ":.aspect_rules_js/{}/segfault-handler@1.3.0/pkg".format(link_root_name): "segfault-handler",
        ":.aspect_rules_js/{}/semver@7.3.8/pkg".format(link_root_name): "semver",
        ":.aspect_rules_js/{}/set-blocking@2.0.0/pkg".format(link_root_name): "set-blocking",
        ":.aspect_rules_js/{}/signal-exit@3.0.7/pkg".format(link_root_name): "signal-exit",
        ":.aspect_rules_js/{}/smart-buffer@4.2.0/pkg".format(link_root_name): "smart-buffer",
        ":.aspect_rules_js/{}/socks@2.7.1/pkg".format(link_root_name): "socks",
        ":.aspect_rules_js/{}/socks-proxy-agent@7.0.0/pkg".format(link_root_name): "socks-proxy-agent",
        ":.aspect_rules_js/{}/ssri@9.0.1/pkg".format(link_root_name): "ssri",
        ":.aspect_rules_js/{}/string-width@4.2.3/pkg".format(link_root_name): "string-width",
        ":.aspect_rules_js/{}/string_decoder@1.3.0/pkg".format(link_root_name): "string_decoder",
        ":.aspect_rules_js/{}/strip-ansi@6.0.1/pkg".format(link_root_name): "strip-ansi",
        ":.aspect_rules_js/{}/tar@6.1.13/pkg".format(link_root_name): "tar",
        ":.aspect_rules_js/{}/unique-filename@2.0.1/pkg".format(link_root_name): "unique-filename",
        ":.aspect_rules_js/{}/unique-slug@3.0.0/pkg".format(link_root_name): "unique-slug",
        ":.aspect_rules_js/{}/util-deprecate@1.0.2/pkg".format(link_root_name): "util-deprecate",
        ":.aspect_rules_js/{}/which@2.0.2/pkg".format(link_root_name): "which",
        ":.aspect_rules_js/{}/wide-align@1.1.5/pkg".format(link_root_name): "wide-align",
        ":.aspect_rules_js/{}/wrappy@1.0.2/pkg".format(link_root_name): "wrappy",
        ":.aspect_rules_js/{}/yallist@4.0.0/pkg".format(link_root_name): "yallist",
    }
    ref_deps = {
        ":.aspect_rules_js/{}/bindings@1.5.0/ref".format(link_root_name): "bindings",
        ":.aspect_rules_js/{}/nan@2.17.0/ref".format(link_root_name): "nan",
        ":.aspect_rules_js/{}/node-gyp@9.3.1/ref".format(link_root_name): "node-gyp",
    }

    store_target_name = ".aspect_rules_js/{}/segfault-handler@1.3.0".format(link_root_name)

    # reference target used to avoid circular deps
    _npm_package_store(
        name = "{}/ref".format(store_target_name),
        package = "segfault-handler",
        version = "1.3.0",
        dev = False,
        tags = ["manual"],
    )

    # post-lifecycle target with reference deps for use in terminal target with transitive closure
    _npm_package_store(
        name = "{}/pkg".format(store_target_name),
        src = "{}/pkg_lc".format(store_target_name) if True else "@@aspect_rules_js~~npm~npm__segfault-handler__1.3.0//:pkg",
        package = "segfault-handler",
        version = "1.3.0",
        dev = False,
        deps = ref_deps,
        tags = ["manual"],
    )

    # virtual store target with transitive closure of all npm package dependencies
    _npm_package_store(
        name = store_target_name,
        src = None if True else "@@aspect_rules_js~~npm~npm__segfault-handler__1.3.0//:pkg",
        package = "segfault-handler",
        version = "1.3.0",
        dev = False,
        deps = deps,
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}/dir".format(store_target_name),
        srcs = [":{}".format(store_target_name)],
        output_group = "package_directory",
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

    lc_deps = {
        ":.aspect_rules_js/{}/@gar+promisify@1.1.3/pkg".format(link_root_name): "@gar/promisify",
        ":.aspect_rules_js/{}/@npmcli+fs@2.1.2/pkg".format(link_root_name): "@npmcli/fs",
        ":.aspect_rules_js/{}/@npmcli+move-file@2.0.1/pkg".format(link_root_name): "@npmcli/move-file",
        ":.aspect_rules_js/{}/@tootallnate+once@2.0.0/pkg".format(link_root_name): "@tootallnate/once",
        ":.aspect_rules_js/{}/abbrev@1.1.1/pkg".format(link_root_name): "abbrev",
        ":.aspect_rules_js/{}/agent-base@6.0.2/pkg".format(link_root_name): "agent-base",
        ":.aspect_rules_js/{}/agentkeepalive@4.2.1/pkg".format(link_root_name): "agentkeepalive",
        ":.aspect_rules_js/{}/aggregate-error@3.1.0/pkg".format(link_root_name): "aggregate-error",
        ":.aspect_rules_js/{}/ansi-regex@5.0.1/pkg".format(link_root_name): "ansi-regex",
        ":.aspect_rules_js/{}/aproba@2.0.0/pkg".format(link_root_name): "aproba",
        ":.aspect_rules_js/{}/are-we-there-yet@3.0.1/pkg".format(link_root_name): "are-we-there-yet",
        ":.aspect_rules_js/{}/balanced-match@1.0.2/pkg".format(link_root_name): "balanced-match",
        ":.aspect_rules_js/{}/bindings@1.5.0/pkg".format(link_root_name): "bindings",
        ":.aspect_rules_js/{}/brace-expansion@1.1.11/pkg".format(link_root_name): "brace-expansion",
        ":.aspect_rules_js/{}/brace-expansion@2.0.1/pkg".format(link_root_name): "brace-expansion",
        ":.aspect_rules_js/{}/cacache@16.1.3/pkg".format(link_root_name): "cacache",
        ":.aspect_rules_js/{}/chownr@2.0.0/pkg".format(link_root_name): "chownr",
        ":.aspect_rules_js/{}/clean-stack@2.2.0/pkg".format(link_root_name): "clean-stack",
        ":.aspect_rules_js/{}/color-support@1.1.3/pkg".format(link_root_name): "color-support",
        ":.aspect_rules_js/{}/concat-map@0.0.1/pkg".format(link_root_name): "concat-map",
        ":.aspect_rules_js/{}/console-control-strings@1.1.0/pkg".format(link_root_name): "console-control-strings",
        ":.aspect_rules_js/{}/debug@4.3.4/pkg".format(link_root_name): "debug",
        ":.aspect_rules_js/{}/delegates@1.0.0/pkg".format(link_root_name): "delegates",
        ":.aspect_rules_js/{}/depd@1.1.2/pkg".format(link_root_name): "depd",
        ":.aspect_rules_js/{}/emoji-regex@8.0.0/pkg".format(link_root_name): "emoji-regex",
        ":.aspect_rules_js/{}/encoding@0.1.13/pkg".format(link_root_name): "encoding",
        ":.aspect_rules_js/{}/env-paths@2.2.1/pkg".format(link_root_name): "env-paths",
        ":.aspect_rules_js/{}/err-code@2.0.3/pkg".format(link_root_name): "err-code",
        ":.aspect_rules_js/{}/file-uri-to-path@1.0.0/pkg".format(link_root_name): "file-uri-to-path",
        ":.aspect_rules_js/{}/fs-minipass@2.1.0/pkg".format(link_root_name): "fs-minipass",
        ":.aspect_rules_js/{}/fs.realpath@1.0.0/pkg".format(link_root_name): "fs.realpath",
        ":.aspect_rules_js/{}/gauge@4.0.4/pkg".format(link_root_name): "gauge",
        ":.aspect_rules_js/{}/glob@7.2.3/pkg".format(link_root_name): "glob",
        ":.aspect_rules_js/{}/glob@8.1.0/pkg".format(link_root_name): "glob",
        ":.aspect_rules_js/{}/graceful-fs@4.2.10/pkg".format(link_root_name): "graceful-fs",
        ":.aspect_rules_js/{}/has-unicode@2.0.1/pkg".format(link_root_name): "has-unicode",
        ":.aspect_rules_js/{}/http-cache-semantics@4.1.1/pkg".format(link_root_name): "http-cache-semantics",
        ":.aspect_rules_js/{}/http-proxy-agent@5.0.0/pkg".format(link_root_name): "http-proxy-agent",
        ":.aspect_rules_js/{}/https-proxy-agent@5.0.1/pkg".format(link_root_name): "https-proxy-agent",
        ":.aspect_rules_js/{}/humanize-ms@1.2.1/pkg".format(link_root_name): "humanize-ms",
        ":.aspect_rules_js/{}/iconv-lite@0.6.3/pkg".format(link_root_name): "iconv-lite",
        ":.aspect_rules_js/{}/imurmurhash@0.1.4/pkg".format(link_root_name): "imurmurhash",
        ":.aspect_rules_js/{}/indent-string@4.0.0/pkg".format(link_root_name): "indent-string",
        ":.aspect_rules_js/{}/infer-owner@1.0.4/pkg".format(link_root_name): "infer-owner",
        ":.aspect_rules_js/{}/inflight@1.0.6/pkg".format(link_root_name): "inflight",
        ":.aspect_rules_js/{}/inherits@2.0.4/pkg".format(link_root_name): "inherits",
        ":.aspect_rules_js/{}/ip@2.0.0/pkg".format(link_root_name): "ip",
        ":.aspect_rules_js/{}/is-fullwidth-code-point@3.0.0/pkg".format(link_root_name): "is-fullwidth-code-point",
        ":.aspect_rules_js/{}/is-lambda@1.0.1/pkg".format(link_root_name): "is-lambda",
        ":.aspect_rules_js/{}/isexe@2.0.0/pkg".format(link_root_name): "isexe",
        ":.aspect_rules_js/{}/lru-cache@6.0.0/pkg".format(link_root_name): "lru-cache",
        ":.aspect_rules_js/{}/lru-cache@7.17.0/pkg".format(link_root_name): "lru-cache",
        ":.aspect_rules_js/{}/make-fetch-happen@10.2.1/pkg".format(link_root_name): "make-fetch-happen",
        ":.aspect_rules_js/{}/minimatch@3.1.2/pkg".format(link_root_name): "minimatch",
        ":.aspect_rules_js/{}/minimatch@5.1.6/pkg".format(link_root_name): "minimatch",
        ":.aspect_rules_js/{}/minipass@3.3.6/pkg".format(link_root_name): "minipass",
        ":.aspect_rules_js/{}/minipass@4.2.4/pkg".format(link_root_name): "minipass",
        ":.aspect_rules_js/{}/minipass-collect@1.0.2/pkg".format(link_root_name): "minipass-collect",
        ":.aspect_rules_js/{}/minipass-fetch@2.1.2/pkg".format(link_root_name): "minipass-fetch",
        ":.aspect_rules_js/{}/minipass-flush@1.0.5/pkg".format(link_root_name): "minipass-flush",
        ":.aspect_rules_js/{}/minipass-pipeline@1.2.4/pkg".format(link_root_name): "minipass-pipeline",
        ":.aspect_rules_js/{}/minipass-sized@1.0.3/pkg".format(link_root_name): "minipass-sized",
        ":.aspect_rules_js/{}/minizlib@2.1.2/pkg".format(link_root_name): "minizlib",
        ":.aspect_rules_js/{}/mkdirp@1.0.4/pkg".format(link_root_name): "mkdirp",
        ":.aspect_rules_js/{}/ms@2.1.2/pkg".format(link_root_name): "ms",
        ":.aspect_rules_js/{}/ms@2.1.3/pkg".format(link_root_name): "ms",
        ":.aspect_rules_js/{}/nan@2.17.0/pkg".format(link_root_name): "nan",
        ":.aspect_rules_js/{}/negotiator@0.6.3/pkg".format(link_root_name): "negotiator",
        ":.aspect_rules_js/{}/node-gyp@9.3.1/pkg".format(link_root_name): "node-gyp",
        ":.aspect_rules_js/{}/nopt@6.0.0/pkg".format(link_root_name): "nopt",
        ":.aspect_rules_js/{}/npmlog@6.0.2/pkg".format(link_root_name): "npmlog",
        ":.aspect_rules_js/{}/once@1.4.0/pkg".format(link_root_name): "once",
        ":.aspect_rules_js/{}/p-map@4.0.0/pkg".format(link_root_name): "p-map",
        ":.aspect_rules_js/{}/path-is-absolute@1.0.1/pkg".format(link_root_name): "path-is-absolute",
        ":.aspect_rules_js/{}/promise-inflight@1.0.1/pkg".format(link_root_name): "promise-inflight",
        ":.aspect_rules_js/{}/promise-retry@2.0.1/pkg".format(link_root_name): "promise-retry",
        ":.aspect_rules_js/{}/readable-stream@3.6.1/pkg".format(link_root_name): "readable-stream",
        ":.aspect_rules_js/{}/retry@0.12.0/pkg".format(link_root_name): "retry",
        ":.aspect_rules_js/{}/rimraf@3.0.2/pkg".format(link_root_name): "rimraf",
        ":.aspect_rules_js/{}/safe-buffer@5.2.1/pkg".format(link_root_name): "safe-buffer",
        ":.aspect_rules_js/{}/safer-buffer@2.1.2/pkg".format(link_root_name): "safer-buffer",
        ":.aspect_rules_js/{}/segfault-handler@1.3.0/pkg_pre_lc_lite".format(link_root_name): "segfault-handler",
        ":.aspect_rules_js/{}/semver@7.3.8/pkg".format(link_root_name): "semver",
        ":.aspect_rules_js/{}/set-blocking@2.0.0/pkg".format(link_root_name): "set-blocking",
        ":.aspect_rules_js/{}/signal-exit@3.0.7/pkg".format(link_root_name): "signal-exit",
        ":.aspect_rules_js/{}/smart-buffer@4.2.0/pkg".format(link_root_name): "smart-buffer",
        ":.aspect_rules_js/{}/socks@2.7.1/pkg".format(link_root_name): "socks",
        ":.aspect_rules_js/{}/socks-proxy-agent@7.0.0/pkg".format(link_root_name): "socks-proxy-agent",
        ":.aspect_rules_js/{}/ssri@9.0.1/pkg".format(link_root_name): "ssri",
        ":.aspect_rules_js/{}/string-width@4.2.3/pkg".format(link_root_name): "string-width",
        ":.aspect_rules_js/{}/string_decoder@1.3.0/pkg".format(link_root_name): "string_decoder",
        ":.aspect_rules_js/{}/strip-ansi@6.0.1/pkg".format(link_root_name): "strip-ansi",
        ":.aspect_rules_js/{}/tar@6.1.13/pkg".format(link_root_name): "tar",
        ":.aspect_rules_js/{}/unique-filename@2.0.1/pkg".format(link_root_name): "unique-filename",
        ":.aspect_rules_js/{}/unique-slug@3.0.0/pkg".format(link_root_name): "unique-slug",
        ":.aspect_rules_js/{}/util-deprecate@1.0.2/pkg".format(link_root_name): "util-deprecate",
        ":.aspect_rules_js/{}/which@2.0.2/pkg".format(link_root_name): "which",
        ":.aspect_rules_js/{}/wide-align@1.1.5/pkg".format(link_root_name): "wide-align",
        ":.aspect_rules_js/{}/wrappy@1.0.2/pkg".format(link_root_name): "wrappy",
        ":.aspect_rules_js/{}/yallist@4.0.0/pkg".format(link_root_name): "yallist",
    }

    # pre-lifecycle target with reference deps for use terminal pre-lifecycle target
    _npm_package_store(
        name = "{}/pkg_pre_lc_lite".format(store_target_name),
        package = "segfault-handler",
        version = "1.3.0",
        dev = False,
        deps = ref_deps,
        tags = ["manual"],
    )

    # terminal pre-lifecycle target for use in lifecycle build target below
    _npm_package_store(
        name = "{}/pkg_pre_lc".format(store_target_name),
        package = "segfault-handler",
        version = "1.3.0",
        dev = False,
        deps = lc_deps,
        tags = ["manual"],
    )

    # lifecycle build action
    _js_run_binary(
        name = "{}/lc".format(store_target_name),
        srcs = [
            "@@aspect_rules_js~~npm~npm__segfault-handler__1.3.0//:pkg",
            ":{}/pkg_pre_lc".format(store_target_name),
        ],
        # js_run_binary runs in the output dir; must add "../../../" because paths are relative to the exec root
        args = [
                   "segfault-handler",
                   "../../../$(execpath @@aspect_rules_js~~npm~npm__segfault-handler__1.3.0//:pkg)",
                   "../../../$(@D)",
               ] +
               select({
                   "@aspect_rules_js//platforms/os:osx": ["--platform=darwin"],
                   "@aspect_rules_js//platforms/os:linux": ["--platform=linux"],
                   "@aspect_rules_js//platforms/os:windows": ["--platform=win32"],
                   "//conditions:default": [],
               }) +
               select({
                   "@aspect_rules_js//platforms/cpu:arm64": ["--arch=arm64"],
                   "@aspect_rules_js//platforms/cpu:x86_64": ["--arch=x64"],
                   "//conditions:default": [],
               }) +
               select({
                   "@aspect_rules_js//platforms/libc:glibc": ["--libc=glibc"],
                   "@aspect_rules_js//platforms/libc:musl": ["--libc=musl"],
                   "//conditions:default": [],
               }),
        copy_srcs_to_bin = False,
        tool = "@aspect_rules_js//npm/private/lifecycle:lifecycle-hooks",
        out_dirs = ["node_modules/.aspect_rules_js/segfault-handler@1.3.0/node_modules/segfault-handler"],
        tags = ["manual"],
        execution_requirements = {
            "no-sandbox": "1",
        },
        mnemonic = "NpmLifecycleHook",
        progress_message = "Running lifecycle hooks on npm package segfault-handler@1.3.0",
        env = {},
        use_default_shell_env = True,
    )

    # post-lifecycle npm_package
    _npm_package_internal(
        name = "{}/pkg_lc".format(store_target_name),
        src = ":{}/lc".format(store_target_name),
        package = "segfault-handler",
        version = "1.3.0",
        tags = ["manual"],
    )

# Generated npm_package_store and npm_link_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_link_imported_package_store(name):
    link_packages = {
        "": ["segfault-handler"],
    }
    if native.package_name() in link_packages:
        link_aliases = link_packages[native.package_name()]
    else:
        link_aliases = ["segfault-handler"]

    link_alias = None
    for _link_alias in link_aliases:
        if name.endswith("/{}".format(_link_alias)):
            # longest match wins
            if not link_alias or len(_link_alias) > len(link_alias):
                link_alias = _link_alias
    if not link_alias:
        msg = "name must end with one of '/{{ {link_aliases_comma_separated} }}' when called from package 'segfault-handler'; recommended value(s) are 'node_modules/{{ {link_aliases_comma_separated} }}'".format(link_aliases_comma_separated = ", ".join(link_aliases))
        fail(msg)

    link_root_name = name[:-len("/{}".format(link_alias))]
    store_target_name = ".aspect_rules_js/{}/segfault-handler@1.3.0".format(link_root_name)

    # terminal package store target to link
    _npm_link_package_store(
        name = name,
        package = link_alias,
        src = "//:{}".format(store_target_name),
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

    # filegroup target that provides a single file which is
    # package directory for use in $(execpath) and $(rootpath)
    native.filegroup(
        name = "{}/dir".format(name),
        srcs = [":{}".format(name)],
        output_group = "package_directory",
        visibility = ["//visibility:public"],
        tags = ["manual"],
    )

    return [":{}".format(name)] if True else []

# Generated npm_package_store and npm_link_package_store targets for npm package segfault-handler@1.3.0
# buildifier: disable=function-docstring
def npm_link_imported_package(
        name = "node_modules",
        link = None,
        fail_if_no_link = True):
    root_package = ""
    link_packages = {
        "": ["segfault-handler"],
    }

    if link_packages and link != None:
        fail("link attribute cannot be specified when link_packages are set")

    is_link = (link == True) or (link == None and native.package_name() in link_packages)
    is_root = native.package_name() == root_package

    if fail_if_no_link and not is_root and not link:
        msg = "Nothing to link in bazel package '%s' for npm package npm package segfault-handler@1.3.0. This is neither the root package nor a link package of this package." % native.package_name()
        fail(msg)

    link_targets = []
    scoped_targets = {}

    if is_link:
        link_aliases = []
        if native.package_name() in link_packages:
            link_aliases = link_packages[native.package_name()]
        if not link_aliases:
            link_aliases = ["segfault-handler"]
        for link_alias in link_aliases:
            link_target_name = "{}/{}".format(name, link_alias)
            npm_link_imported_package_store(name = link_target_name)
            if True:
                link_targets.append(":{}".format(link_target_name))
                if len(link_alias.split("/", 1)) > 1:
                    link_scope = link_alias.split("/", 1)[0]
                    if link_scope not in scoped_targets:
                        scoped_targets[link_scope] = []
                    scoped_targets[link_scope].append(link_target_name)

    if is_root:
        npm_imported_package_store("{}/segfault-handler".format(name))

    return (link_targets, scoped_targets)
