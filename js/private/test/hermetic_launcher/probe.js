// The js_binary entry point the hermetic launcher bakes in. Reports what
// launcher.cjs reconstructed, so the test can check it against what the bash
// launcher would have set up.
const fs = require('fs')
const path = require('path')

const report = (key, value) => console.log(`${key}=${value}`)

// launcher.cjs must consume `--bazel-bindir <path>` rather than leave it for the
// program, and everything after it must arrive untouched.
report('args', process.argv.slice(2).join(' '))
report('bazel_bindir', process.env.BAZEL_BINDIR)

// bootstrap.cjs only applies the fs patches when both of these are set, and only
// launcher.cjs can set them here.
report('depth', process.env.JS_BINARY__NODE_PATCHES_DEPTH)
report('fs_patched', fs._unpatched ? 'yes' : 'no')
report('patch_roots_match', process.env.JS_BINARY__FS_PATCH_ROOTS ===
    `${process.env.JS_BINARY__EXECROOT}:${process.env.JS_BINARY__RUNFILES}` ? 'yes' : 'no')

// These have to be absolute: the launcher may change directory after computing them.
report('runfiles_absolute', path.isAbsolute(process.env.JS_BINARY__RUNFILES || '') ? 'yes' : 'no')
report('execroot_absolute', path.isAbsolute(process.env.JS_BINARY__EXECROOT || '') ? 'yes' : 'no')

// A child that shells out to `node` has to find the patched wrapper first, and the
// wrapper itself reads these two.
const wrapper = process.env.JS_BINARY__NODE_WRAPPER || ''
report('wrapper_is_file', fs.existsSync(wrapper) ? 'yes' : 'no')
report('wrapper_first_on_path', (process.env.PATH || '').split(path.delimiter)[0] ===
    path.dirname(wrapper) ? 'yes' : 'no')
report('node_binary_is_file', fs.existsSync(process.env.JS_BINARY__NODE_BINARY || '') ? 'yes' : 'no')

// Must be byte-identical to what the launcher passed, or a child process loads two
// spellings of the preload and fs.cjs throws on the second patch.
const requireIndex = process.execArgv.indexOf('--require')
report('node_patches_match',
    process.env.JS_BINARY__NODE_PATCHES === process.execArgv[requireIndex + 1] ? 'yes' : 'no')

// bootstrap.cjs points execPath at the wrapper; either way it must name a real file.
report('exec_path_is_file', fs.existsSync(process.execPath) ? 'yes' : 'no')

// aspect-build/rules_js#2937
report('compile_cache_disabled', process.env.NODE_DISABLE_COMPILE_CACHE)

// node resolves and absolutizes the main entry before preloads run, which is what
// lets launcher.cjs change directory without relocating the entry point.
report('main_absolute', path.isAbsolute(process.argv[1]) ? 'yes' : 'no')

// --preserve-symlinks-main is a node CLI flag, so it can only come from the launcher.
report('preserve_symlinks_main', process.execArgv.includes('--preserve-symlinks-main') ? 'yes' : 'no')
