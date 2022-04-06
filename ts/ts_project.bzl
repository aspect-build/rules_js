"""Public API for TypeScript rules

Nearly identical to the ts_project wrapper macro in npm @bazel/typescript.
Differences:
- this doesn't have the transpiler attribute yet
- doesn't have worker support
- uses the executables from @npm_typescript rather than what a user npm_install'ed
- didn't copy the whole doc string
"""

load("@aspect_bazel_lib//lib:utils.bzl", "is_external_label")

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_config.bzl", "write_tsconfig", _ts_config = "ts_config")

# buildifier: disable=bzl-visibility
load("@rules_nodejs//nodejs/private:ts_lib.bzl", _lib = "lib")
load("//ts/private:ts_project.bzl", "validate_options", _ts_project = "ts_project")

ts_config = _ts_config

# buildifier: disable=function-docstring-args
def ts_project(
        name,
        tsconfig = "tsconfig.json",
        srcs = None,
        args = [],
        data = [],
        deps = [],
        extends = None,
        allow_js = False,
        declaration = False,
        source_map = False,
        declaration_map = False,
        resolve_json_module = None,
        preserve_jsx = False,
        composite = False,
        incremental = False,
        emit_declaration_only = False,
        ts_build_info_file = None,
        tsc = "@npm_typescript//:tsc",
        validate = True,
        validator = "@npm_typescript//:validator",
        declaration_dir = None,
        out_dir = None,
        root_dir = None,
        **kwargs):
    """Compiles one TypeScript project using `tsc --project`.

    For the list of args, see the ts_project rule.
    """

    if srcs == None:
        include = ["**/*.ts", "**/*.tsx"]
        exclude = []
        if allow_js == True:
            include.extend(["**/*.js", "**/*.jsx"])
        if resolve_json_module == True:
            include.append("**/*.json")
            exclude.extend(["**/package.json", "**/package-lock.json", "**/tsconfig*.json"])
        srcs = native.glob(include, exclude)
    tsc_deps = deps

    common_kwargs = {
        "tags": kwargs.get("tags", []),
        "visibility": kwargs.get("visibility", None),
        "testonly": kwargs.get("testonly", None),
    }

    if type(tsconfig) == type(dict()):
        # Copy attributes <-> tsconfig properties
        # TODO: fail if compilerOptions includes a conflict with an attribute?
        compiler_options = tsconfig.setdefault("compilerOptions", {})
        source_map = compiler_options.setdefault("sourceMap", source_map)
        declaration = compiler_options.setdefault("declaration", declaration)
        declaration_map = compiler_options.setdefault("declarationMap", declaration_map)
        emit_declaration_only = compiler_options.setdefault("emitDeclarationOnly", emit_declaration_only)
        allow_js = compiler_options.setdefault("allowJs", allow_js)
        if resolve_json_module != None:
            resolve_json_module = compiler_options.setdefault("resolveJsonModule", resolve_json_module)

        # These options are always passed on the tsc command line so don't include them
        # in the tsconfig. At best they're redundant, but at worst we'll have a conflict
        if "outDir" in compiler_options.keys():
            out_dir = compiler_options.pop("outDir")
        if "declarationDir" in compiler_options.keys():
            declaration_dir = compiler_options.pop("declarationDir")
        if "rootDir" in compiler_options.keys():
            root_dir = compiler_options.pop("rootDir")

        # FIXME: need to remove keys that have a None value?
        write_tsconfig(
            name = "_gen_tsconfig_%s" % name,
            config = tsconfig,
            files = srcs,
            extends = Label("%s//%s:%s" % (native.repository_name(), native.package_name(), name)).relative(extends) if extends else None,
            out = "tsconfig_%s.json" % name,
            allow_js = allow_js,
            resolve_json_module = resolve_json_module,
        )

        # From here, tsconfig becomes a file, the same as if the
        # user supplied a tsconfig.json InputArtifact
        tsconfig = "tsconfig_%s.json" % name

    elif validate:
        validate_options(
            name = "_validate_%s_options" % name,
            target = "//%s:%s" % (native.package_name(), name),
            declaration = declaration,
            source_map = source_map,
            declaration_map = declaration_map,
            preserve_jsx = preserve_jsx,
            composite = composite,
            incremental = incremental,
            ts_build_info_file = ts_build_info_file,
            emit_declaration_only = emit_declaration_only,
            resolve_json_module = resolve_json_module,
            allow_js = allow_js,
            tsconfig = tsconfig,
            extends = extends,
            has_local_deps = len([d for d in deps if not is_external_label(d)]) > 0,
            validator = validator,
            **common_kwargs
        )
        tsc_deps = tsc_deps + ["_validate_%s_options" % name]

    typings_out_dir = declaration_dir if declaration_dir else out_dir
    tsbuildinfo_path = ts_build_info_file if ts_build_info_file else name + ".tsbuildinfo"

    js_outs = _lib.calculate_js_outs(srcs, out_dir, root_dir, allow_js, preserve_jsx, emit_declaration_only)
    map_outs = _lib.calculate_map_outs(srcs, out_dir, root_dir, source_map, preserve_jsx, emit_declaration_only)
    typings_outs = _lib.calculate_typings_outs(srcs, typings_out_dir, root_dir, declaration, composite, allow_js)
    typing_maps_outs = _lib.calculate_typing_maps_outs(srcs, typings_out_dir, root_dir, declaration_map, allow_js)

    _ts_project(
        name = name,
        srcs = srcs,
        args = args,
        data = data,
        deps = tsc_deps,
        tsconfig = tsconfig,
        allow_js = allow_js,
        extends = extends,
        incremental = incremental,
        preserve_jsx = preserve_jsx,
        composite = composite,
        declaration = declaration,
        declaration_dir = declaration_dir,
        source_map = source_map,
        declaration_map = declaration_map,
        out_dir = out_dir,
        root_dir = root_dir,
        js_outs = js_outs,
        map_outs = map_outs,
        typings_outs = typings_outs,
        typing_maps_outs = typing_maps_outs,
        buildinfo_out = tsbuildinfo_path if composite or incremental else None,
        emit_declaration_only = emit_declaration_only,
        tsc = tsc,
        # TODO: support transpiler attribute when we have a js_library equivalent
        # and can copy over the logic from rules_nodejs to set tsc_js_outs, ts_map_outs
        # and create all the targets for transpilation
        transpile = True,
        # We don't support this feature at all from rules_js
        supports_workers = False,
        **kwargs
    )
