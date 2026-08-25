// Preload for the hermetic launcher, which invokes node directly rather than
// through js_binary.sh.tpl. It reconstructs the parts of that script's runtime
// contract that a process which only execve's cannot set up, then hands off to
// bootstrap.cjs.
//
// Everything here is derived from process.execPath, process.execArgv, __dirname,
// process.cwd() and the environment, so this file needs no per-target generation.
// __dirname is what makes that work: this file always sits at
// <runfiles>/<repo>/js/private/node-bootstrap/, whatever the repo is called.
//
// The per-target constants the bash launcher bakes in -- JS_BINARY__WORKSPACE,
// JS_BINARY__TARGET, JS_BINARY__PACKAGE, JS_BINARY__BUILD_FILE_PATH,
// JS_BINARY__COMPILATION_MODE, JS_BINARY__TARGET_CPU, JS_BINARY__BINDIR -- are
// deliberately not reconstructed. They are unreachable from here.
//
// Ordering matters: bootstrap.cjs destructures process.env at module load, so
// every variable it reads has to be set before the require at the bottom.

const fs = require('fs')
const path = require('path')
const { pathToFileURL } = require('url')

// A module loaded under two path spellings runs twice, and fs.cjs throws rather
// than patch twice. Make the second run a no-op.
const GUARD = Symbol.for('aspect_rules_js.hermetic_launcher')

// Node worker threads inherit execArgv, so this preload runs in every one of them, and
// three of the things it does belong to the main thread alone:
//
//   - Changing directory. process.chdir throws ERR_WORKER_UNSUPPORTED_OPERATION in a
//     worker, which does not need it anyway: it inherits the cwd the main thread
//     already moved to.
//   - Redirecting the main module. A worker's main is the script it was started with
//     rather than the js_binary entry point, and process.argv[1] is not even set there.
//   - Turning COVERAGE_DIR into NODE_V8_COVERAGE, which takes a fresh node. A worker
//     inherits an environment that already has the variable, and replacing the process
//     out from under the main thread is not something it could survive anyway.
//
// Everything else here still has to happen in a worker, because the fs patches apply per
// realm.
//
// The bash launcher never met any of this: the shell did its cd before node started, and
// nothing inside node changed directory or chose a main afterwards. rollup running terser
// is a real target that does both.
const IS_MAIN_THREAD = require('worker_threads').isMainThread

const LOG_PREFIX = 'aspect_rules_js[js_binary]'

// The runfiles directory name of the main repository. rules_js is bzlmod-only, and
// bzlmod always names it `_main` -- which is what both bazel-lib's to_rlocation_path and
// hermetic_launcher itself already assume. If it ever were something else the derived
// entry point would not exist, and redirectMainToExecroot fatals naming the path it
// looked for rather than running the wrong file.
const MAIN_REPO_PREFIX = '_main/'

// Features of the bash launcher that this one cannot implement: each needs work after
// the program exits, and this launcher is execve'd over. Nothing in rules_js sets them
// -- js_run_binary's stdout, stderr, exit_code_out and silent_on_success go through
// run_binary's wrapper, and expected_exit_code keeps a js_binary off this launcher
// altogether -- so reaching one means an `env` that asked for the script's
// implementation of it by hand. Say so rather than silently not writing an output file
// or not suppressing output.
const UNSUPPORTED = [
    'JS_BINARY__STDOUT_OUTPUT_FILE',
    'JS_BINARY__STDERR_OUTPUT_FILE',
    'JS_BINARY__EXIT_CODE_OUTPUT_FILE',
    'JS_BINARY__EXPECTED_EXIT_CODE',
    'JS_BINARY__SILENT_ON_SUCCESS',
]

function fatal(message) {
    process.stderr.write(`FATAL: ${LOG_PREFIX}: ${message}\n`)
    process.exit(1)
}

function debug(message) {
    if (process.env.JS_BINARY__LOG_DEBUG) {
        process.stderr.write(`DEBUG: ${LOG_PREFIX}: ${message}\n`)
    }
}

function isDirectory(p) {
    try {
        return fs.statSync(p).isDirectory()
    } catch {
        return false
    }
}

// Port of resolve_execroot_bin_path in js_binary.sh.tpl.
function resolveExecrootBinPath(shortPath, execroot) {
    const bindir = process.env.BAZEL_BINDIR || process.env.JS_BINARY__BINDIR || ''
    return shortPath.startsWith('../')
        ? path.join(execroot, bindir, 'external', shortPath.slice(3))
        : path.join(execroot, bindir, shortPath)
}

// The launcher passes `--bazel-bindir <path>` ahead of the program's own
// arguments and expects it to be consumed here; if it survived into process.argv
// the program would read it as a positional argument.
//
// Not necessarily at index 2: the js_binary's `fixed_args` are embedded in the
// launcher binary, so they come first, exactly as the launcher script puts them
// before the arguments it was invoked with. Which is why a fixed arg spelled
// `--bazel-bindir` keeps a target off this launcher -- it would be found here
// instead of the real one.
//
// Returns whether the flag was there, which is also the answer to "is this the
// process the build action launched?". js_run_binary appends it to every action, and it
// is consumed here, so a child process that re-enters node -- through the node wrapper
// on the PATH, with this file preloaded again -- never sees it. Only BAZEL_BINDIR's
// value is inherited.
function takeBazelBindir() {
    const at = process.argv.indexOf('--bazel-bindir', 2)
    if (at === -1) {
        return false
    }
    if (process.argv.length < at + 2) {
        fatal('--bazel-bindir flag requires a value')
    }
    process.env.BAZEL_BINDIR = process.argv[at + 1]
    process.argv.splice(at, 2)
    return true
}

// The bash launcher turns these into node CLI flags. By the time a preload runs
// node has already parsed its options, so they can only be rejected.
function rejectNodeOptions() {
    for (const arg of process.argv.slice(2)) {
        if (arg.startsWith('--node_options=')) {
            fatal(
                `${arg} is not supported by this launcher; set node options at ` +
                    `build time with the js_binary node_options attribute`
            )
        }
    }
}

// Port of BASH_INITIALIZE_RUNFILES in js/private/bash.bzl, minus the cases that
// cannot arise here: the launcher binary always hands us RUNFILES_DIR or
// RUNFILES_MANIFEST_FILE, so there is no $0 walk.
function resolveRunfiles(startCwd) {
    let runfiles = process.env.RUNFILES_DIR
    if (!runfiles && process.env.RUNFILES_MANIFEST_FILE) {
        const manifest = process.env.RUNFILES_MANIFEST_FILE
        if (manifest.endsWith('.runfiles_manifest')) {
            runfiles = manifest.slice(0, -'_manifest'.length)
        } else if (manifest.endsWith('/MANIFEST')) {
            runfiles = manifest.slice(0, -'/MANIFEST'.length)
        } else {
            fatal(`Unexpected RUNFILES_MANIFEST_FILE value ${manifest}`)
        }
    }
    if (!runfiles) {
        fatal('RUNFILES_DIR environment variable is not set')
    }
    // Must be absolute: we may be about to change directory.
    return path.resolve(startCwd, runfiles)
}

// Port of the execroot derivation and `cd $BAZEL_BINDIR` in js_binary.sh.tpl.
// Kept structurally identical to the bash, because the shape of the condition is
// what makes the three cases work without asking which one we are in: under
// `bazel run` the cwd is inside the runfiles tree and there is no BAZEL_BINDIR,
// in a build action the cwd is the execroot, and a nested js_binary already
// sitting in the bindir declines to change directory a second time.
function resolveExecroot(startCwd) {
    const segments = ['/bazel-out/', '/BAZEL-~1/', '/bazel-~1/']
    const segment = segments.find((s) => startCwd.includes(s))
    const bindir = process.env.BAZEL_BINDIR
    const inherited = process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT
        ? process.env.JS_BINARY__EXECROOT
        : undefined

    if (segment && (!bindir || !isDirectory(path.join(startCwd, bindir)))) {
        // In the runfiles tree and the execroot is not yet known; strip from the
        // last bazel-out segment.
        return inherited || startCwd.slice(0, startCwd.lastIndexOf(segment))
    }

    const execroot = inherited || startCwd
    if (!process.env.JS_BINARY__NO_CD_BINDIR && IS_MAIN_THREAD) {
        if (!bindir) {
            fatal(
                'BAZEL_BINDIR must be set in environment to the makevar $(BINDIR) in js_binary ' +
                    'build actions (which run in the execroot) so that build actions can change ' +
                    'directories to always run out of the root of the Bazel output tree. If this ' +
                    "is not a build action you can set BAZEL_BINDIR to '.' instead to suppress " +
                    'this error.'
            )
        }
        debug(`changing directory to BAZEL_BINDIR (root of Bazel output tree) ${bindir}`)
        process.chdir(bindir)
    }
    return execroot
}

// The path this file was preloaded from. Not __dirname, which node has already resolved
// through the runfiles symlink back to the source tree; the files beside this one have to
// be reached inside the runfiles tree the launcher binary resolved against.
function preloadPath() {
    const at = process.execArgv.indexOf('--require')
    return at !== -1 && process.execArgv[at + 1] ? process.execArgv[at + 1] : __filename
}

// Every child process that re-enters node has to be able to find a patched one.
function setUpNode() {
    // Read before bootstrap.cjs overwrites process.execPath with the wrapper.
    process.env.JS_BINARY__NODE_BINARY = process.execPath

    // Taken back out of execArgv rather than recomputed, so that it is byte-for-byte
    // the string the launcher passed. A child that inherits execArgv and also picks
    // this up from the node wrapper would otherwise load two spellings of the same
    // module and fs.cjs would throw on the second patch.
    const preload = preloadPath()
    process.env.JS_BINARY__NODE_PATCHES = preload

    const wrapper = path.join(path.dirname(preload), '..', 'node_bin', 'node')
    if (!fs.existsSync(wrapper)) {
        fatal(`node wrapper '${wrapper}' not found`)
    }
    process.env.JS_BINARY__NODE_WRAPPER = wrapper

    // So that a child process which shells out to `node` gets the patched runtime.
    process.env.PATH = process.env.PATH
        ? `${path.dirname(wrapper)}${path.delimiter}${process.env.PATH}`
        : path.dirname(wrapper)
}

// Whether node will load `file` through the ESM loader rather than the CJS one, by the
// same rule node uses: the extension, or failing that the nearest package.json "type".
// Only consulted on the re-exec path below, so it stays off the fast path.
function isEsmMain(file) {
    if (file.endsWith('.mjs')) {
        return true
    }
    if (file.endsWith('.cjs')) {
        return false
    }
    for (let dir = path.dirname(file); ; ) {
        const manifest = path.join(dir, 'package.json')
        if (fs.existsSync(manifest)) {
            try {
                return JSON.parse(fs.readFileSync(manifest, 'utf8')).type === 'module'
            } catch {
                return false
            }
        }
        const parent = path.dirname(dir)
        if (parent === dir) {
            return false
        }
        dir = parent
    }
}

// Starts node over again on `mainScript`, with the same options and the same arguments,
// and does not return. The two things a preload cannot do to the node it is already
// running in both end up here.
//
// process.execve replaces this process rather than adding one, which is what the launcher
// script's `exec` did and costs the same nothing. A node too old to have it forks and
// waits instead -- and that is the same vintage of node that makes the ESM caller below
// necessary at all.
function reExec(mainScript, env, reason) {
    debug(`re-executing node on ${mainScript}: ${reason}`)
    const argv = [...process.execArgv, mainScript, ...process.argv.slice(2)]
    if (typeof process.execve === 'function') {
        process.execve(process.execPath, [process.execPath, ...argv], env)
    }
    const result = require('child_process').spawnSync(process.execPath, argv, {
        env,
        stdio: 'inherit',
    })
    if (result.error) {
        fatal(`could not re-execute node on '${mainScript}': ${result.error.message}`)
    }
    if (result.signal) {
        process.kill(process.pid, result.signal)
    }
    process.exit(result.status === null ? 1 : result.status)
}

// Port of the coverage block in js_binary.sh.tpl, plus the JS_BINARY__COVERAGE_REPORT
// that js_binary bakes into the script next to it.
//
// node reads NODE_V8_COVERAGE once, when it opens its V8 coverage connection during
// startup, so a preload cannot turn coverage on for the process it is running in: by the
// time this file loads the decision has been made. Handing the variable to a fresh node
// is the only way to honour COVERAGE_DIR.
//
// Only the first node in the tree does that, and finding NODE_V8_COVERAGE already set is
// what says a process is not it: the one started below runs straight through, and so does
// every child, each of which node gives a coverage connection of its own at its own
// startup. A child must not claim the report a second time either, which is why
// coverage.cjs deletes JS_BINARY__COVERAGE_REPORT as soon as it has taken it.
function setUpCoverage() {
    if (!process.env.COVERAGE_DIR || process.env.NODE_V8_COVERAGE || !IS_MAIN_THREAD) {
        return
    }
    // Absolute for the same reason the runfiles root is. node resolves the coverage
    // directory against the cwd of whichever process it starts in, and this launcher
    // changes directory before the program gets to spawn anything.
    const dir = path.resolve(process.env.COVERAGE_DIR)
    const env = { ...process.env, NODE_V8_COVERAGE: dir }

    // The report generator that coverage.cjs runs when the program exits. The launcher
    // script has its path baked in by js_binary; here it is derived from the preload's
    // own path, the way setUpNode derives the node wrapper. js_binary puts it in the
    // runfiles exactly when it decided this target reports coverage, so whether it is
    // there is the same answer to the same question.
    const report = path.join(path.dirname(preloadPath()), '..', 'coverage', 'coverage.js')
    if (fs.existsSync(report)) {
        env.JS_BINARY__COVERAGE_REPORT = report
    }

    reExec(process.argv[1], env, `v8 coverage support needs NODE_V8_COVERAGE=${dir}`)
}

// Port of the entry point selection in js_binary.sh.tpl. The launcher binary can only
// bake a runfiles rlocation -- its one argument transformation resolves against the
// runfiles root and nothing else -- so when the caller asked for the execroot entry point
// the bindir copy has to be found here, and node has to be told to treat it as the main
// module.
//
// Which copy runs is the whole of the difference between the two modes. node resolves
// `node_modules` by walking up from the directory of the main module, so this is what
// decides whether the program sees the tool's runfiles tree or the target-configuration
// bin tree that the action's srcs and outputs also live in.
function redirectMainToExecroot(runfiles, execroot) {
    // The launcher script builds this from $BAZEL_BINDIR and fails without it. Here the
    // consequence of carrying on would be worse than an error: resolveExecrootBinPath
    // would join an empty bindir and land on the source tree.
    if (!process.env.BAZEL_BINDIR) {
        fatal(
            'BAZEL_BINDIR must be set in environment when JS_BINARY__USE_EXECROOT_ENTRY_POINT is set'
        )
    }

    // argv[1] is the runfiles path the launcher resolved, and an rlocation path differs
    // from a short path only in its first segment, so the short path this needs is
    // recoverable without spending an embedded argument on it.
    const requested = process.argv[1]
    const rlocation = path.relative(runfiles, requested)
    const shortPath = rlocation.startsWith(MAIN_REPO_PREFIX)
        ? rlocation.slice(MAIN_REPO_PREFIX.length)
        : '../' + rlocation
    const entryPoint = resolveExecrootBinPath(shortPath, execroot)
    if (!fs.existsSync(entryPoint)) {
        fatal(`the entry_point '${entryPoint}' not found`)
    }
    debug(`using the execroot entry point ${entryPoint}`)

    // What the launcher script hands node, so a program reading argv[1] sees the same
    // path either way.
    process.argv[1] = entryPoint

    const Module = require('module')

    // node captured the main it was given before any preload ran, but it has not resolved
    // it yet -- so the resolution is the hook. Returning the bindir path here is what
    // makes it the main module, with its own directory as the module search root, and
    // nothing is realpath'd on the way, which is what --preserve-symlinks-main would
    // otherwise have been doing for the entry point.
    const resolveFilename = Module._resolveFilename
    Module._resolveFilename = function (request, parent, isMain, options) {
        if (isMain) {
            Module._resolveFilename = resolveFilename
            return entryPoint
        }
        return resolveFilename.apply(this, arguments)
    }

    // An ESM main never reaches that hook: node resolves it through the ESM loader, which
    // has its own. Both are installed rather than choosing between them, so that neither
    // this file nor js_binary has to work out which loader node will pick.
    if (typeof Module.registerHooks !== 'function') {
        // A node old enough to lack module.registerHooks gives a preload no way to
        // redirect an ESM main, so run a second node on the right file rather than let
        // this one load the runfiles copy and resolve the program's imports against the
        // wrong tree. The child's argv carries no --bazel-bindir -- takeBazelBindir
        // already removed it -- so it will not redirect its main a second time.
        if (isEsmMain(entryPoint)) {
            reExec(entryPoint, process.env, 'this node cannot redirect an ESM main')
        }
        return
    }
    const requestedUrl = pathToFileURL(requested).href
    const entryPointUrl = pathToFileURL(entryPoint).href
    Module.registerHooks({
        resolve(specifier, context, nextResolve) {
            if (context.parentURL === undefined && specifier === requestedUrl) {
                return { url: entryPointUrl, shortCircuit: true }
            }
            return nextResolve(specifier, context)
        },
    })
}

function main() {
    for (const name of UNSUPPORTED) {
        if (process.env[name]) {
            fatal(`${name} is set, which this launcher does not implement`)
        }
    }

    // Before anything below touches process.argv or the cwd, because this may replace
    // the process rather than return.
    setUpCoverage()

    // Everything below is computed against the directory we started in, which
    // resolveExecroot may change.
    const startCwd = process.cwd()

    const isActionLaunch = takeBazelBindir()
    rejectNodeOptions()

    const runfiles = resolveRunfiles(startCwd)
    process.env.RUNFILES_DIR = runfiles
    process.env.JS_BINARY__RUNFILES = runfiles

    const execroot = resolveExecroot(startCwd)
    process.env.JS_BINARY__EXECROOT = execroot

    // Only the process the action launched has an entry point to choose; a child that
    // re-enters node was given its own script to run, and the launcher script would not
    // have touched that either -- it runs once per action, not once per node process.
    //
    // js_binary.sh.tpl also takes the execroot entry point when JS_BINARY__NO_RUNFILES is
    // set. That cannot arise here: the launcher binary needs a runfiles tree to resolve
    // its own arguments against, and js_binary keeps a target with runfiles disabled off
    // this launcher.
    if (
        isActionLaunch &&
        IS_MAIN_THREAD &&
        process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT
    ) {
        redirectMainToExecroot(runfiles, execroot)
    }

    setUpNode()

    // Don't override a value set by an outer js_binary; without this bootstrap.cjs
    // applies no fs patches at all.
    if (!process.env.JS_BINARY__FS_PATCH_ROOTS) {
        // ':' rather than path.delimiter, because bootstrap.cjs splits on ':'.
        process.env.JS_BINARY__FS_PATCH_ROOTS = `${execroot}:${runfiles}`
    }
    // JS_BINARY__PATCH_NODE_FS is deliberately not defaulted here. It is a per-target
    // value the launcher binary has no way to carry, and js_run_binary always sets it
    // explicitly -- to "0" as well as to "1" -- so in a build action the environment is
    // already authoritative. Inventing a default here would override `patch_node_fs =
    // False` rather than honour it.
    if (!process.env.JS_BINARY__LOG_PREFIX) {
        process.env.JS_BINARY__LOG_PREFIX = LOG_PREFIX
    }

    // aspect-build/rules_js#2937
    if (!process.env.NODE_COMPILE_CACHE && !process.env.NODE_DISABLE_COMPILE_CACHE) {
        process.env.NODE_DISABLE_COMPILE_CACHE = '1'
    }

    // Also once per action, and for the same reason as the entry point above: a child
    // that re-enters node has already inherited the directory, and chdir'ing again would
    // resolve this relative path against it, looking for <chdir>/<chdir>. The `cd` in
    // resolveExecroot is already safe against that by construction, since it tests for
    // the bindir below the cwd before moving.
    if (process.env.JS_BINARY__CHDIR && IS_MAIN_THREAD && isActionLaunch) {
        const target = process.env.JS_BINARY__CHDIR
        debug(`changing directory to user specified package ${target}`)
        process.chdir(
            target.startsWith('external/')
                ? resolveExecrootBinPath(target, execroot)
                : target
        )
    }
}

if (!globalThis[GUARD]) {
    globalThis[GUARD] = true
    main()
    require('./bootstrap.cjs')
}
