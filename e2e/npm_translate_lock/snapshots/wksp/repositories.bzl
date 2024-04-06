"""@generated by npm_translate_lock(name = "npm", pnpm_lock = "@//:pnpm-lock.yaml")"""

load("@aspect_rules_js//npm:repositories.bzl", "npm_import")

# Generated npm_import repository rules corresponding to npm packages in @//:pnpm-lock.yaml
# buildifier: disable=function-docstring
def npm_repositories():
    npm_import(
        name = "npm__at_rollup_plugin-commonjs__23.0.4",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["@rollup/plugin-commonjs"],
        },
        package = "@rollup/plugin-commonjs",
        version = "23.0.4",
        url = "https://registry.npmjs.org/@rollup/plugin-commonjs/-/plugin-commonjs-23.0.4.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-bOPJeTZg56D2MCm+TT4psP8e8Jmf1Jsi7pFUMl8BN5kOADNzofNHe47+84WVCt7D095xPghC235/YKuNDEhczg==",
        deps = {
            "@rollup/pluginutils": "5.0.2",
            "commondir": "registry.npmjs.org/commondir@1.0.1",
            "estree-walker": "registry.npmjs.org/estree-walker@2.0.2",
            "glob": "registry.npmjs.org/glob@8.1.0",
            "is-reference": "registry.npmjs.org/is-reference@1.2.1",
            "magic-string": "registry.npmjs.org/magic-string@0.26.7",
        },
        transitive_closure = {
            "@rollup/plugin-commonjs": ["23.0.4"],
            "@rollup/pluginutils": ["5.0.2"],
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
            "balanced-match": ["registry.npmjs.org/balanced-match@1.0.2"],
            "brace-expansion": ["registry.npmjs.org/brace-expansion@2.0.1"],
            "commondir": ["registry.npmjs.org/commondir@1.0.1"],
            "estree-walker": ["registry.npmjs.org/estree-walker@2.0.2"],
            "fs.realpath": ["registry.npmjs.org/fs.realpath@1.0.0"],
            "glob": ["registry.npmjs.org/glob@8.1.0"],
            "inflight": ["registry.npmjs.org/inflight@1.0.6"],
            "inherits": ["registry.npmjs.org/inherits@2.0.4"],
            "is-reference": ["registry.npmjs.org/is-reference@1.2.1"],
            "magic-string": ["registry.npmjs.org/magic-string@0.26.7"],
            "minimatch": ["registry.npmjs.org/minimatch@5.1.6"],
            "once": ["registry.npmjs.org/once@1.4.0"],
            "picomatch": ["registry.npmjs.org/picomatch@2.3.1"],
            "sourcemap-codec": ["registry.npmjs.org/sourcemap-codec@1.4.8"],
            "wrappy": ["registry.npmjs.org/wrappy@1.0.2"],
        },
    )

    npm_import(
        name = "npm__at_rollup_plugin-json__5.0.2",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["@rollup/plugin-json"],
        },
        package = "@rollup/plugin-json",
        version = "5.0.2",
        url = "https://registry.npmjs.org/@rollup/plugin-json/-/plugin-json-5.0.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-D1CoOT2wPvadWLhVcmpkDnesTzjhNIQRWLsc3fA49IFOP2Y84cFOOJ+nKGYedvXHKUsPeq07HR4hXpBBr+CHlA==",
        deps = {
            "@rollup/pluginutils": "5.0.2",
        },
        transitive_closure = {
            "@rollup/plugin-json": ["5.0.2"],
            "@rollup/pluginutils": ["5.0.2"],
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
            "estree-walker": ["registry.npmjs.org/estree-walker@2.0.2"],
            "picomatch": ["registry.npmjs.org/picomatch@2.3.1"],
        },
    )

    npm_import(
        name = "npm__at_rollup_plugin-node-resolve__15.0.1",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["@rollup/plugin-node-resolve"],
        },
        package = "@rollup/plugin-node-resolve",
        version = "15.0.1",
        url = "https://registry.npmjs.org/@rollup/plugin-node-resolve/-/plugin-node-resolve-15.0.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-ReY88T7JhJjeRVbfCyNj+NXAG3IIsVMsX9b5/9jC98dRP8/yxlZdz7mHZbHk5zHr24wZZICS5AcXsFZAXYUQEg==",
        deps = {
            "@rollup/pluginutils": "5.0.2",
            "@types/resolve": "registry.npmjs.org/@types/resolve@1.20.2",
            "deepmerge": "registry.npmjs.org/deepmerge@4.3.0",
            "is-builtin-module": "registry.npmjs.org/is-builtin-module@3.2.1",
            "is-module": "registry.npmjs.org/is-module@1.0.0",
            "resolve": "registry.npmjs.org/resolve@1.22.1",
        },
        transitive_closure = {
            "@rollup/plugin-node-resolve": ["15.0.1"],
            "@rollup/pluginutils": ["5.0.2"],
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
            "@types/resolve": ["registry.npmjs.org/@types/resolve@1.20.2"],
            "builtin-modules": ["registry.npmjs.org/builtin-modules@3.3.0"],
            "deepmerge": ["registry.npmjs.org/deepmerge@4.3.0"],
            "estree-walker": ["registry.npmjs.org/estree-walker@2.0.2"],
            "function-bind": ["registry.npmjs.org/function-bind@1.1.1"],
            "has": ["registry.npmjs.org/has@1.0.3"],
            "is-builtin-module": ["registry.npmjs.org/is-builtin-module@3.2.1"],
            "is-core-module": ["registry.npmjs.org/is-core-module@2.11.0"],
            "is-module": ["registry.npmjs.org/is-module@1.0.0"],
            "path-parse": ["registry.npmjs.org/path-parse@1.0.7"],
            "picomatch": ["registry.npmjs.org/picomatch@2.3.1"],
            "resolve": ["registry.npmjs.org/resolve@1.22.1"],
            "supports-preserve-symlinks-flag": ["registry.npmjs.org/supports-preserve-symlinks-flag@1.0.0"],
        },
    )

    npm_import(
        name = "npm__at_rollup_pluginutils__5.0.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "@rollup/pluginutils",
        version = "5.0.2",
        url = "https://registry.npmjs.org/@rollup/pluginutils/-/pluginutils-5.0.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-pTd9rIsP92h+B6wWwFbW8RkZv4hiR/xKsqre4SIuAOaOEQRxi0lqLke9k2/7WegC85GgUs9pjmOjCUi3In4vwA==",
        deps = {
            "@types/estree": "registry.npmjs.org/@types/estree@1.0.0",
            "estree-walker": "registry.npmjs.org/estree-walker@2.0.2",
            "picomatch": "registry.npmjs.org/picomatch@2.3.1",
        },
        transitive_closure = {
            "@rollup/pluginutils": ["5.0.2"],
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
            "estree-walker": ["registry.npmjs.org/estree-walker@2.0.2"],
            "picomatch": ["registry.npmjs.org/picomatch@2.3.1"],
        },
    )

    npm_import(
        name = "npm__at_types_estree__registry.npmjs.org_at_types_estree_1.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "@types/estree",
        version = "registry.npmjs.org/@types/estree@1.0.0",
        url = "https://registry.yarnpkg.com/@types/estree/-/estree-1.0.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-WulqXMDUTYAXCjZnk6JtIHPigp55cVtDgDrO2gHRwhyJto21+1zbVCtOYB2L1F9w4qCQ0rOGWBnBe0FNTiEJIQ==",
        transitive_closure = {
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
        },
    )

    npm_import(
        name = "npm__at_types_node__registry.npmjs.org_at_types_node_18.11.18",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["@types/node"],
        },
        package = "@types/node",
        version = "registry.npmjs.org/@types/node@18.11.18",
        url = "https://registry.yarnpkg.com/@types/node/-/node-18.11.18.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-DHQpWGjyQKSHj3ebjFI/wRKcqQcdR+MoFBygntYOZytCqNfkd2ZC4ARDJ2DQqhjH5p85Nnd3jhUJIXrszFX/JA==",
        transitive_closure = {
            "@types/node": ["registry.npmjs.org/@types/node@18.11.18"],
        },
    )

    npm_import(
        name = "npm__at_types_resolve__registry.npmjs.org_at_types_resolve_1.20.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "@types/resolve",
        version = "registry.npmjs.org/@types/resolve@1.20.2",
        url = "https://registry.yarnpkg.com/@types/resolve/-/resolve-1.20.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-60BCwRFOZCQhDncwQdxxeOEEkbc5dIMccYLwbxsS4TUNeVECQ/pBJ0j09mrHOl/JJvpRPGwO9SvE4nR2Nb/a4Q==",
        transitive_closure = {
            "@types/resolve": ["registry.npmjs.org/@types/resolve@1.20.2"],
        },
    )

    npm_import(
        name = "npm__at_types_semver__registry.npmjs.org_at_types_semver_7.3.13",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["@types/semver"],
        },
        package = "@types/semver",
        version = "registry.npmjs.org/@types/semver@7.3.13",
        url = "https://registry.yarnpkg.com/@types/semver/-/semver-7.3.13.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-21cFJr9z3g5dW8B0CVI9g2O9beqaThGQ6ZFBqHfwhzLDKUxaqTIy3vnfah/UPkfOiF2pLq+tGz+W8RyCskuslw==",
        transitive_closure = {
            "@types/semver": ["registry.npmjs.org/@types/semver@7.3.13"],
        },
    )

    npm_import(
        name = "npm__balanced-match__registry.npmjs.org_balanced-match_1.0.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "balanced-match",
        version = "registry.npmjs.org/balanced-match@1.0.2",
        url = "https://registry.yarnpkg.com/balanced-match/-/balanced-match-1.0.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-3oSeUO0TMV67hN1AmbXsK4yaqU7tjiHlbxRDZOpH0KW9+CeX4bRAaX0Anxt0tx2MrpRpWwQaPwIlISEJhYU5Pw==",
        transitive_closure = {
            "balanced-match": ["registry.npmjs.org/balanced-match@1.0.2"],
        },
    )

    npm_import(
        name = "npm__brace-expansion__registry.npmjs.org_brace-expansion_2.0.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "brace-expansion",
        version = "registry.npmjs.org/brace-expansion@2.0.1",
        url = "https://registry.yarnpkg.com/brace-expansion/-/brace-expansion-2.0.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-XnAIvQ8eM+kC6aULx6wuQiwVsnzsi9d3WxzV3FpWTGA19F621kwdbsAcFKXgKUHZWsy+mY6iL1sHTxWEFCytDA==",
        deps = {
            "balanced-match": "registry.npmjs.org/balanced-match@1.0.2",
        },
        transitive_closure = {
            "balanced-match": ["registry.npmjs.org/balanced-match@1.0.2"],
            "brace-expansion": ["registry.npmjs.org/brace-expansion@2.0.1"],
        },
    )

    npm_import(
        name = "npm__builtin-modules__registry.npmjs.org_builtin-modules_3.3.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "builtin-modules",
        version = "registry.npmjs.org/builtin-modules@3.3.0",
        url = "https://registry.yarnpkg.com/builtin-modules/-/builtin-modules-3.3.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-zhaCDicdLuWN5UbN5IMnFqNMhNfo919sH85y2/ea+5Yg9TsTkeZxpL+JLbp6cgYFS4sRLp3YV4S6yDuqVWHYOw==",
        transitive_closure = {
            "builtin-modules": ["registry.npmjs.org/builtin-modules@3.3.0"],
        },
    )

    npm_import(
        name = "npm__commondir__registry.npmjs.org_commondir_1.0.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "commondir",
        version = "registry.npmjs.org/commondir@1.0.1",
        url = "https://registry.yarnpkg.com/commondir/-/commondir-1.0.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-W9pAhw0ja1Edb5GVdIF1mjZw/ASI0AlShXM83UUGe2DVr5TdAPEA1OA8m/g8zWp9x6On7gqufY+FatDbC3MDQg==",
        transitive_closure = {
            "commondir": ["registry.npmjs.org/commondir@1.0.1"],
        },
    )

    npm_import(
        name = "npm__debug__registry.npmjs.org_debug_4.3.4",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["debug"],
        },
        package = "debug",
        version = "registry.npmjs.org/debug@4.3.4",
        url = "https://registry.yarnpkg.com/debug/-/debug-4.3.4.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-PRWFHuSU3eDtQJPvnNY7Jcket1j0t5OuOsFzPPzsekD52Zl8qUfFIPEiswXqIvHWGVHOgX+7G/vCNNhehwxfkQ==",
        deps = {
            "ms": "registry.npmjs.org/ms@2.1.2",
        },
        transitive_closure = {
            "debug": ["registry.npmjs.org/debug@4.3.4"],
            "ms": ["registry.npmjs.org/ms@2.1.2"],
        },
    )

    npm_import(
        name = "npm__deepmerge__registry.npmjs.org_deepmerge_4.3.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "deepmerge",
        version = "registry.npmjs.org/deepmerge@4.3.0",
        url = "https://registry.yarnpkg.com/deepmerge/-/deepmerge-4.3.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-z2wJZXrmeHdvYJp/Ux55wIjqo81G5Bp4c+oELTW+7ar6SogWHajt5a9gO3s3IDaGSAXjDk0vlQKN3rms8ab3og==",
        transitive_closure = {
            "deepmerge": ["registry.npmjs.org/deepmerge@4.3.0"],
        },
    )

    npm_import(
        name = "npm__estree-walker__registry.npmjs.org_estree-walker_2.0.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "estree-walker",
        version = "registry.npmjs.org/estree-walker@2.0.2",
        url = "https://registry.yarnpkg.com/estree-walker/-/estree-walker-2.0.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-Rfkk/Mp/DL7JVje3u18FxFujQlTNR2q6QfMSMB7AvCBx91NGj/ba3kCfza0f6dVDbw7YlRf/nDrn7pQrCCyQ/w==",
        transitive_closure = {
            "estree-walker": ["registry.npmjs.org/estree-walker@2.0.2"],
        },
    )

    npm_import(
        name = "npm__fs.realpath__registry.npmjs.org_fs.realpath_1.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "fs.realpath",
        version = "registry.npmjs.org/fs.realpath@1.0.0",
        url = "https://registry.yarnpkg.com/fs.realpath/-/fs.realpath-1.0.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-OO0pH2lK6a0hZnAdau5ItzHPI6pUlvI7jMVnxUQRtw4owF2wk8lOSabtGDCTP4Ggrg2MbGnWO9X8K1t4+fGMDw==",
        transitive_closure = {
            "fs.realpath": ["registry.npmjs.org/fs.realpath@1.0.0"],
        },
    )

    npm_import(
        name = "npm__function-bind__registry.npmjs.org_function-bind_1.1.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "function-bind",
        version = "registry.npmjs.org/function-bind@1.1.1",
        url = "https://registry.yarnpkg.com/function-bind/-/function-bind-1.1.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-yIovAzMX49sF8Yl58fSCWJ5svSLuaibPxXQJFLmBObTuCr0Mf1KiPopGM9NiFjiYBCbfaa2Fh6breQ6ANVTI0A==",
        transitive_closure = {
            "function-bind": ["registry.npmjs.org/function-bind@1.1.1"],
        },
    )

    npm_import(
        name = "npm__glob__registry.npmjs.org_glob_8.1.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "glob",
        version = "registry.npmjs.org/glob@8.1.0",
        url = "https://registry.yarnpkg.com/glob/-/glob-8.1.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-r8hpEjiQEYlF2QU0df3dS+nxxSIreXQS1qRhMJM0Q5NDdR386C7jb7Hwwod8Fgiuex+k0GFjgft18yvxm5XoCQ==",
        deps = {
            "fs.realpath": "registry.npmjs.org/fs.realpath@1.0.0",
            "inflight": "registry.npmjs.org/inflight@1.0.6",
            "inherits": "registry.npmjs.org/inherits@2.0.4",
            "minimatch": "registry.npmjs.org/minimatch@5.1.6",
            "once": "registry.npmjs.org/once@1.4.0",
        },
        transitive_closure = {
            "balanced-match": ["registry.npmjs.org/balanced-match@1.0.2"],
            "brace-expansion": ["registry.npmjs.org/brace-expansion@2.0.1"],
            "fs.realpath": ["registry.npmjs.org/fs.realpath@1.0.0"],
            "glob": ["registry.npmjs.org/glob@8.1.0"],
            "inflight": ["registry.npmjs.org/inflight@1.0.6"],
            "inherits": ["registry.npmjs.org/inherits@2.0.4"],
            "minimatch": ["registry.npmjs.org/minimatch@5.1.6"],
            "once": ["registry.npmjs.org/once@1.4.0"],
            "wrappy": ["registry.npmjs.org/wrappy@1.0.2"],
        },
    )

    npm_import(
        name = "npm__has__registry.npmjs.org_has_1.0.3",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "has",
        version = "registry.npmjs.org/has@1.0.3",
        url = "https://registry.yarnpkg.com/has/-/has-1.0.3.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-f2dvO0VU6Oej7RkWJGrehjbzMAjFp5/VKPp5tTpWIV4JHHZK1/BxbFRtf/siA2SWTe09caDmVtYYzWEIbBS4zw==",
        deps = {
            "function-bind": "registry.npmjs.org/function-bind@1.1.1",
        },
        transitive_closure = {
            "function-bind": ["registry.npmjs.org/function-bind@1.1.1"],
            "has": ["registry.npmjs.org/has@1.0.3"],
        },
    )

    npm_import(
        name = "npm__inflight__registry.npmjs.org_inflight_1.0.6",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "inflight",
        version = "registry.npmjs.org/inflight@1.0.6",
        url = "https://registry.yarnpkg.com/inflight/-/inflight-1.0.6.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-k92I/b08q4wvFscXCLvqfsHCrjrF7yiXsQuIVvVE7N82W3+aqpzuUdBbfhWcy/FZR3/4IgflMgKLOsvPDrGCJA==",
        deps = {
            "once": "registry.npmjs.org/once@1.4.0",
            "wrappy": "registry.npmjs.org/wrappy@1.0.2",
        },
        transitive_closure = {
            "inflight": ["registry.npmjs.org/inflight@1.0.6"],
            "once": ["registry.npmjs.org/once@1.4.0"],
            "wrappy": ["registry.npmjs.org/wrappy@1.0.2"],
        },
    )

    npm_import(
        name = "npm__inherits__registry.npmjs.org_inherits_2.0.4",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "inherits",
        version = "registry.npmjs.org/inherits@2.0.4",
        url = "https://registry.yarnpkg.com/inherits/-/inherits-2.0.4.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-k/vGaX4/Yla3WzyMCvTQOXYeIHvqOKtnqBduzTHpzpQZzAskKMhZ2K+EnBiSM9zGSoIFeMpXKxa4dYeZIQqewQ==",
        transitive_closure = {
            "inherits": ["registry.npmjs.org/inherits@2.0.4"],
        },
    )

    npm_import(
        name = "npm__is-builtin-module__registry.npmjs.org_is-builtin-module_3.2.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "is-builtin-module",
        version = "registry.npmjs.org/is-builtin-module@3.2.1",
        url = "https://registry.yarnpkg.com/is-builtin-module/-/is-builtin-module-3.2.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-BSLE3HnV2syZ0FK0iMA/yUGplUeMmNz4AW5fnTunbCIqZi4vG3WjJT9FHMy5D69xmAYBHXQhJdALdpwVxV501A==",
        deps = {
            "builtin-modules": "registry.npmjs.org/builtin-modules@3.3.0",
        },
        transitive_closure = {
            "builtin-modules": ["registry.npmjs.org/builtin-modules@3.3.0"],
            "is-builtin-module": ["registry.npmjs.org/is-builtin-module@3.2.1"],
        },
    )

    npm_import(
        name = "npm__is-core-module__registry.npmjs.org_is-core-module_2.11.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "is-core-module",
        version = "registry.npmjs.org/is-core-module@2.11.0",
        url = "https://registry.yarnpkg.com/is-core-module/-/is-core-module-2.11.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-RRjxlvLDkD1YJwDbroBHMb+cukurkDWNyHx7D3oNB5x9rb5ogcksMC5wHCadcXoo67gVr/+3GFySh3134zi6rw==",
        deps = {
            "has": "registry.npmjs.org/has@1.0.3",
        },
        transitive_closure = {
            "function-bind": ["registry.npmjs.org/function-bind@1.1.1"],
            "has": ["registry.npmjs.org/has@1.0.3"],
            "is-core-module": ["registry.npmjs.org/is-core-module@2.11.0"],
        },
    )

    npm_import(
        name = "npm__is-module__registry.npmjs.org_is-module_1.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "is-module",
        version = "registry.npmjs.org/is-module@1.0.0",
        url = "https://registry.yarnpkg.com/is-module/-/is-module-1.0.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-51ypPSPCoTEIN9dy5Oy+h4pShgJmPCygKfyRCISBI+JoWT/2oJvK8QPxmwv7b/p239jXrm9M1mlQbyKJ5A152g==",
        transitive_closure = {
            "is-module": ["registry.npmjs.org/is-module@1.0.0"],
        },
    )

    npm_import(
        name = "npm__is-number__registry.npmjs.org_is-number_6.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "is-number",
        version = "registry.npmjs.org/is-number@6.0.0",
        url = "https://registry.yarnpkg.com/is-number/-/is-number-6.0.0.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-Wu1VHeILBK8KAWJUAiSZQX94GmOE45Rg6/538fKwiloUu21KncEkYGPqob2oSZ5mUT73vLGrHQjKw3KMPwfDzg==",
        transitive_closure = {
            "is-number": ["registry.npmjs.org/is-number@6.0.0"],
        },
    )

    npm_import(
        name = "npm__is-odd__registry.npmjs.org_is-odd_3.0.1",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["is-odd"],
        },
        package = "is-odd",
        version = "registry.npmjs.org/is-odd@3.0.1",
        url = "https://registry.yarnpkg.com/is-odd/-/is-odd-3.0.1.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-CQpnWPrDwmP1+SMHXZhtLtJv90yiyVfluGsX5iNCVkrhQtU3TQHsUWPG9wkdk9Lgd5yNpAg9jQEo90CBaXgWMA==",
        deps = {
            "is-number": "registry.npmjs.org/is-number@6.0.0",
        },
        transitive_closure = {
            "is-number": ["registry.npmjs.org/is-number@6.0.0"],
            "is-odd": ["registry.npmjs.org/is-odd@3.0.1"],
        },
    )

    npm_import(
        name = "npm__is-reference__registry.npmjs.org_is-reference_1.2.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "is-reference",
        version = "registry.npmjs.org/is-reference@1.2.1",
        url = "https://registry.yarnpkg.com/is-reference/-/is-reference-1.2.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-U82MsXXiFIrjCK4otLT+o2NA2Cd2g5MLoOVXUZjIOhLurrRxpEXzI8O0KZHr3IjLvlAH1kTPYSuqer5T9ZVBKQ==",
        deps = {
            "@types/estree": "registry.npmjs.org/@types/estree@1.0.0",
        },
        transitive_closure = {
            "@types/estree": ["registry.npmjs.org/@types/estree@1.0.0"],
            "is-reference": ["registry.npmjs.org/is-reference@1.2.1"],
        },
    )

    npm_import(
        name = "npm__lru-cache__registry.npmjs.org_lru-cache_6.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "lru-cache",
        version = "registry.npmjs.org/lru-cache@6.0.0",
        url = "https://registry.yarnpkg.com/lru-cache/-/lru-cache-6.0.0.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-Jo6dJ04CmSjuznwJSS3pUeWmd/H0ffTlkXXgwZi+eq1UCmqQwCh+eLsYOYCwY991i2Fah4h1BEMCx4qThGbsiA==",
        deps = {
            "yallist": "registry.npmjs.org/yallist@4.0.0",
        },
        transitive_closure = {
            "lru-cache": ["registry.npmjs.org/lru-cache@6.0.0"],
            "yallist": ["registry.npmjs.org/yallist@4.0.0"],
        },
    )

    npm_import(
        name = "npm__magic-string__registry.npmjs.org_magic-string_0.26.7",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "magic-string",
        version = "registry.npmjs.org/magic-string@0.26.7",
        url = "https://registry.yarnpkg.com/magic-string/-/magic-string-0.26.7.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-hX9XH3ziStPoPhJxLq1syWuZMxbDvGNbVchfrdCtanC7D13888bMFow61x8axrx+GfHLtVeAx2kxL7tTGRl+Ow==",
        deps = {
            "sourcemap-codec": "registry.npmjs.org/sourcemap-codec@1.4.8",
        },
        transitive_closure = {
            "magic-string": ["registry.npmjs.org/magic-string@0.26.7"],
            "sourcemap-codec": ["registry.npmjs.org/sourcemap-codec@1.4.8"],
        },
    )

    npm_import(
        name = "npm__minimatch__registry.npmjs.org_minimatch_5.1.6",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "minimatch",
        version = "registry.npmjs.org/minimatch@5.1.6",
        url = "https://registry.yarnpkg.com/minimatch/-/minimatch-5.1.6.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-lKwV/1brpG6mBUFHtb7NUmtABCb2WZZmm2wNiOA5hAb8VdCS4B3dtMWyvcoViccwAW/COERjXLt0zP1zXUN26g==",
        deps = {
            "brace-expansion": "registry.npmjs.org/brace-expansion@2.0.1",
        },
        transitive_closure = {
            "balanced-match": ["registry.npmjs.org/balanced-match@1.0.2"],
            "brace-expansion": ["registry.npmjs.org/brace-expansion@2.0.1"],
            "minimatch": ["registry.npmjs.org/minimatch@5.1.6"],
        },
    )

    npm_import(
        name = "npm__ms__registry.npmjs.org_ms_2.1.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "ms",
        version = "registry.npmjs.org/ms@2.1.2",
        url = "https://registry.yarnpkg.com/ms/-/ms-2.1.2.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-sGkPx+VjMtmA6MX27oA4FBFELFCZZ4S4XqeGOXCv68tT+jb3vk/RyaKWP0PTKyWtmLSM0b+adUTEvbs1PEaH2w==",
        transitive_closure = {
            "ms": ["registry.npmjs.org/ms@2.1.2"],
        },
    )

    npm_import(
        name = "npm__once__registry.npmjs.org_once_1.4.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "once",
        version = "registry.npmjs.org/once@1.4.0",
        url = "https://registry.yarnpkg.com/once/-/once-1.4.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-lNaJgI+2Q5URQBkccEKHTQOPaXdUxnZZElQTZY0MFUAuaEqe1E+Nyvgdz/aIyNi6Z9MzO5dv1H8n58/GELp3+w==",
        deps = {
            "wrappy": "registry.npmjs.org/wrappy@1.0.2",
        },
        transitive_closure = {
            "once": ["registry.npmjs.org/once@1.4.0"],
            "wrappy": ["registry.npmjs.org/wrappy@1.0.2"],
        },
    )

    npm_import(
        name = "npm__path-parse__registry.npmjs.org_path-parse_1.0.7",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "path-parse",
        version = "registry.npmjs.org/path-parse@1.0.7",
        url = "https://registry.yarnpkg.com/path-parse/-/path-parse-1.0.7.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-LDJzPVEEEPR+y48z93A0Ed0yXb8pAByGWo/k5YYdYgpY2/2EsOsksJrq7lOHxryrVOn1ejG6oAp8ahvOIQD8sw==",
        transitive_closure = {
            "path-parse": ["registry.npmjs.org/path-parse@1.0.7"],
        },
    )

    npm_import(
        name = "npm__picomatch__registry.npmjs.org_picomatch_2.3.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "picomatch",
        version = "registry.npmjs.org/picomatch@2.3.1",
        url = "https://registry.yarnpkg.com/picomatch/-/picomatch-2.3.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-JU3teHTNjmE2VCGFzuY8EXzCDVwEqB2a8fsIvwaStHhAWJEeVd1o1QD80CU6+ZdEXXSLbSsuLwJjkCBWqRQUVA==",
        transitive_closure = {
            "picomatch": ["registry.npmjs.org/picomatch@2.3.1"],
        },
    )

    npm_import(
        name = "npm__resolve__registry.npmjs.org_resolve_1.22.1",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "resolve",
        version = "registry.npmjs.org/resolve@1.22.1",
        url = "https://registry.yarnpkg.com/resolve/-/resolve-1.22.1.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-nBpuuYuY5jFsli/JIs1oldw6fOQCBioohqWZg/2hiaOybXOft4lonv85uDOKXdf8rhyK159cxU5cDcK/NKk8zw==",
        deps = {
            "is-core-module": "registry.npmjs.org/is-core-module@2.11.0",
            "path-parse": "registry.npmjs.org/path-parse@1.0.7",
            "supports-preserve-symlinks-flag": "registry.npmjs.org/supports-preserve-symlinks-flag@1.0.0",
        },
        transitive_closure = {
            "function-bind": ["registry.npmjs.org/function-bind@1.1.1"],
            "has": ["registry.npmjs.org/has@1.0.3"],
            "is-core-module": ["registry.npmjs.org/is-core-module@2.11.0"],
            "path-parse": ["registry.npmjs.org/path-parse@1.0.7"],
            "resolve": ["registry.npmjs.org/resolve@1.22.1"],
            "supports-preserve-symlinks-flag": ["registry.npmjs.org/supports-preserve-symlinks-flag@1.0.0"],
        },
    )

    npm_import(
        name = "npm__semver__registry.npmjs.org_semver_7.5.1",
        root_package = "",
        link_workspace = "",
        link_packages = {
            "": ["semver"],
        },
        package = "semver",
        version = "registry.npmjs.org/semver@7.5.1",
        url = "https://registry.yarnpkg.com/semver/-/semver-7.5.1.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-Wvss5ivl8TMRZXXESstBA4uR5iXgEN/VC5/sOcuXdVLzcdkz4HWetIoRfG5gb5X+ij/G9rw9YoGn3QoQ8OCSpw==",
        deps = {
            "lru-cache": "registry.npmjs.org/lru-cache@6.0.0",
        },
        transitive_closure = {
            "lru-cache": ["registry.npmjs.org/lru-cache@6.0.0"],
            "semver": ["registry.npmjs.org/semver@7.5.1"],
            "yallist": ["registry.npmjs.org/yallist@4.0.0"],
        },
    )

    npm_import(
        name = "npm__sourcemap-codec__registry.npmjs.org_sourcemap-codec_1.4.8",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "sourcemap-codec",
        version = "registry.npmjs.org/sourcemap-codec@1.4.8",
        url = "https://registry.yarnpkg.com/sourcemap-codec/-/sourcemap-codec-1.4.8.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-9NykojV5Uih4lgo5So5dtw+f0JgJX30KCNI8gwhz2J9A15wD0Ml6tjHKwf6fTSa6fAdVBdZeNOs9eJ71qCk8vA==",
        transitive_closure = {
            "sourcemap-codec": ["registry.npmjs.org/sourcemap-codec@1.4.8"],
        },
    )

    npm_import(
        name = "npm__supports-preserve-symlinks-flag__registry.npmjs.org_supports-preserve-symlinks-flag_1.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "supports-preserve-symlinks-flag",
        version = "registry.npmjs.org/supports-preserve-symlinks-flag@1.0.0",
        url = "https://registry.yarnpkg.com/supports-preserve-symlinks-flag/-/supports-preserve-symlinks-flag-1.0.0.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-ot0WnXS9fgdkgIcePe6RHNk1WA8+muPa6cSjeR3V8K27q9BB1rTE3R1p7Hv0z1ZyAc8s6Vvv8DIyWf681MAt0w==",
        transitive_closure = {
            "supports-preserve-symlinks-flag": ["registry.npmjs.org/supports-preserve-symlinks-flag@1.0.0"],
        },
    )

    npm_import(
        name = "npm__wrappy__registry.npmjs.org_wrappy_1.0.2",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "wrappy",
        version = "registry.npmjs.org/wrappy@1.0.2",
        url = "https://registry.yarnpkg.com/wrappy/-/wrappy-1.0.2.tgz",
        package_visibility = ["//visibility:public"],
        dev = True,
        integrity = "sha512-l4Sp/DRseor9wL6EvV2+TuQn63dMkPjZ/sp9XkghTEbV9KlPS1xUsZ3u7/IQO4wxtcFB4bgpQPRcR3QCvezPcQ==",
        transitive_closure = {
            "wrappy": ["registry.npmjs.org/wrappy@1.0.2"],
        },
    )

    npm_import(
        name = "npm__yallist__registry.npmjs.org_yallist_4.0.0",
        root_package = "",
        link_workspace = "",
        link_packages = {},
        package = "yallist",
        version = "registry.npmjs.org/yallist@4.0.0",
        url = "https://registry.yarnpkg.com/yallist/-/yallist-4.0.0.tgz",
        package_visibility = ["//visibility:public"],
        integrity = "sha512-3wdGidZyq5PB084XLES5TpOSRA3wjXAlIWMhum2kRcv/41Sn2emQ0dycQW4uZXLejwKvg6EsvbdlVL+FYEct7A==",
        transitive_closure = {
            "yallist": ["registry.npmjs.org/yallist@4.0.0"],
        },
    )
