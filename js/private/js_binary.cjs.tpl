// This JavaScript file is the launcher for the NodeJS JavaScript file
// entry point with the following bazel label:
//     {{entry_point_label}}
//
// The launcher was generated to execute the js_binary target
//     {{target_label}}
//
// The template used to generate this launcher is
//     {{template_label}}
//
// It is the hermetic launcher's counterpart to js_binary.sh.tpl, and does the same job: work
// out where node, the entry point and the per-launch preload are, set the environment the
// target asked for, and start node on them. Everything that can wait until node is up lives in
// js/private/node-bootstrap/launcher.cjs, which both launchers load as node's first --require.

'use strict'

// The replacement sets global.JS_IMAGE_LAYER, which the env block below reads.
// This line is replaced by js_image_layer to make the launcher hermetic.

const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')

// ==============================================================================
// Values baked in at analysis time
// ==============================================================================

const WORKSPACE_NAME = {{workspace_name}}
const ENTRY_POINT_PATH = {{entry_point_path}}
const NODE_PATH = {{node}}
const NPM_PATH = {{npm}}
const LOG_PREFIX_RULE_SET = {{log_prefix_rule_set}}
const LOG_PREFIX_RULE = {{log_prefix_rule}}
// The node options the launcher's own process was already started with, by the native stub.
const STUB_NODE_OPTIONS = {{stub_node_options}}
// Worked out at analysis time; see _env_configures_node_startup in js/private/js_binary.bzl.
const ENV_CONFIGURES_NODE_STARTUP = {{env_configures_node_startup}}

// ==============================================================================
// Shared helpers
// ==============================================================================

// The per-launch preload, resolved out of the runfiles by the stub before node started and
// handed to this launcher as its first argument. The helpers both launchers use sit beside
// it, so the same argument finds them, and finding them is the first thing done here because
// everything below needs them.
//
// Made absolute against the directory this launcher was started in, before the chdir below
// moves it: the stub resolves an rlocation to a relative path when it was given a relative
// runfiles directory, and a relative specifier with no leading "./" is a package name to
// require().
const launcher = path.resolve(process.argv[2])
const {
    checkExecutableFile,
    isDirectory,
    logDebug,
    logError,
    logFatal,
    logInfo,
    withSlashes,
} = require(path.join(path.dirname(launcher), 'util.cjs'))

// The env values, node options, and fixed args below were spliced into
// double-quoted bash strings before this launcher was ported to JavaScript, so
// shell parameter expansion happened at launch time and users depend on it. For
// example, examples/stack_traces passes
// node_options = ["--require", "$$JS_BINARY__RUNFILES/$$JS_BINARY__WORKSPACE/..."].
// Only $VAR / ${VAR} expansion is reproduced here; command substitution is not,
// and the result is not re-split on whitespace the way bash would have.
function expandEnvRefs(value) {
    return value.replace(
        /\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))/g,
        (_match, braced, bare) => process.env[braced || bare] || ''
    )
}

function setEnv(name, value) {
    process.env[name] = expandEnvRefs(value)
}

// An empty value counts as unset, matching the `[[ -z ]]` test the bash launcher
// writes for the same env entry.
function setEnvIfUnset(name, value) {
    if (!process.env[name]) {
        process.env[name] = expandEnvRefs(value)
    }
}

// ==============================================================================
// Environment
// ==============================================================================

{{envs}}

// ==============================================================================
// Handle --bazel-bindir flag
// ==============================================================================

// If a --bazel-bindir <path> flag is passed it must be the first two
// arguments. It is consumed by this launcher and used to set BAZEL_BINDIR,
// overriding any value already set in the environment.
//
// The caller's arguments start at index 3: node's own argv[0] and argv[1], then the preload
// the stub resolved above.
const argv = process.argv.slice(3)
if (argv.length > 0 && argv[0] === '--bazel-bindir') {
    if (argv.length < 2) {
        fs.writeSync(2, 'ERROR: --bazel-bindir flag requires a value\n')
        process.exit(1)
    }
    process.env.BAZEL_BINDIR = argv[1]
    argv.splice(0, 2)
}

// ==============================================================================
// Prepare logging
// ==============================================================================

// Read by the shared log functions on every call, so it has to be set before the first of
// them runs.
process.env.JS_BINARY__LOG_PREFIX = `${LOG_PREFIX_RULE_SET}[${LOG_PREFIX_RULE}]`

function exitWith(exitCode) {
    logDebug(`exit code: ${exitCode}`)
    process.exit(exitCode)
}

// ==============================================================================
// Runfiles initialization
// ==============================================================================

// The hermetic_launcher stub should have already initialized RUNFILES_DIR.
const runfiles = process.env.RUNFILES_DIR
if (!runfiles) {
    logFatal('RUNFILES_DIR environment variable is not set')
    exitWith(1)
}

// JS_BINARY__RUNFILES is documented to be an absolute path to the runfiles
// directory, so we need to uphold that guarantee.
process.env.JS_BINARY__RUNFILES = withSlashes(path.resolve(runfiles))

// ==============================================================================
// Prepare to run main program
// ==============================================================================

// The execroot the entry point is resolved against below. A parent js_binary process hands its
// own down when it asks for an execroot entry point, because the entry point it resolved is in
// that tree; otherwise this launcher was started in it. Nothing else here needs an execroot:
// the preload works out JS_BINARY__EXECROOT for the program and everything it spawns.
const execroot =
    process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT &&
    process.env.JS_BINARY__EXECROOT
        ? withSlashes(process.env.JS_BINARY__EXECROOT)
        : withSlashes(process.cwd())

// Build actions are started in the execroot, so change into the root of the Bazel output tree,
// which is where js_binary programs run. See
// https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
// for more context on why we do this. It cannot wait for the preload: node resolves the bare
// specifier of a --require in node_options against the directory it was started in.
//
// The bindir is only there to change into when this really is an execroot; in a runfiles tree,
// or in a nested js_binary already running in the bindir, there is nothing to do. The preload
// tells those apart from the broken case by JS_BINARY__CHANGED_TO_BINDIR.
if (
    !process.env.JS_BINARY__NO_CD_BINDIR &&
    process.env.BAZEL_BINDIR &&
    isDirectory(process.env.BAZEL_BINDIR)
) {
    logDebug(
        `changing directory to BAZEL_BINDIR (root of Bazel output tree) ${process.env.BAZEL_BINDIR}`
    )
    process.env.JS_BINARY__CHANGED_TO_BINDIR = '1'
    process.chdir(process.env.BAZEL_BINDIR)
    process.env.PWD = process.cwd()
}

if (
    process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT &&
    !process.env.BAZEL_BINDIR
) {
    logFatal(
        'Expected BAZEL_BINDIR to be set when JS_BINARY__USE_EXECROOT_ENTRY_POINT is set'
    )
    exitWith(1)
}

function resolveExecrootBinPath(shortPath) {
    // The bash launcher gets this from `set -o nounset`; without it an unset BAZEL_BINDIR
    // silently builds '<execroot>/undefined/<path>' and only surfaces as a missing entry point.
    if (!process.env.BAZEL_BINDIR) {
        logFatal(
            'BAZEL_BINDIR must be set in the environment to the makevar $(BINDIR) to resolve a path in the Bazel output tree'
        )
        exitWith(1)
    }
    if (shortPath.startsWith('../')) {
        return `${execroot}/${process.env.BAZEL_BINDIR}/external/${shortPath.slice(3)}`
    }
    return `${execroot}/${process.env.BAZEL_BINDIR}/${shortPath}`
}

function resolveExecrootSrcPath(shortPath) {
    if (shortPath.startsWith('../')) {
        return `${execroot}/external/${shortPath.slice(3)}`
    }
    return `${execroot}/${shortPath}`
}

// Resolve a toolchain file that is a file of this workspace or another repository
// in the runfiles tree, or an absolute path a user set in node_toolchain.
function resolveToolchainPath(file) {
    // Only an absolute path can arrive with backslashes, from a node_toolchain a
    // user configured; a short path baked in above uses '/' on every platform.
    if (path.isAbsolute(file)) {
        return withSlashes(file)
    }
    if (process.env.JS_BINARY__NO_RUNFILES) {
        return resolveExecrootSrcPath(file)
    }
    return `${process.env.JS_BINARY__RUNFILES}/${WORKSPACE_NAME}/${file}`
}

// Everything below is resolved here only because node needs it on its command line
// or this launcher needs it to start node at all. The checks that can wait, and the rest of
// the environment the program sees, are done by the preload once node is up.

let entryPoint
if (
    process.env.JS_BINARY__USE_EXECROOT_ENTRY_POINT ||
    process.env.JS_BINARY__NO_RUNFILES
) {
    entryPoint = resolveExecrootBinPath(ENTRY_POINT_PATH)
} else {
    entryPoint = `${process.env.JS_BINARY__RUNFILES}/${WORKSPACE_NAME}/${ENTRY_POINT_PATH}`
}

process.env.JS_BINARY__NODE_BINARY = resolveToolchainPath(NODE_PATH)
checkExecutableFile('node binary', process.env.JS_BINARY__NODE_BINARY)

if (NPM_PATH) {
    process.env.JS_BINARY__NPM_BINARY = resolveToolchainPath(NPM_PATH)
}

// Gather node options
const nodeOptions = []
function addNodeOption(value) {
    nodeOptions.push(expandEnvRefs(value))
}
{{node_options}}

// fixed_args were tokenized at analysis time, each token as a list of
// [text, expand] segments: bash removed the quotes but this launcher still has to
// know which of them were single quotes, since those are the ones whose $VAR the
// shell would not have expanded. Expansion itself happens now, at run time.
const FIXED_ARGS = {{fixed_args}}.map((segments) =>
    segments.map(([text, expand]) => (expand ? expandEnvRefs(text) : text)).join('')
)

const args = []
for (const arg of [...FIXED_ARGS, ...argv]) {
    if (arg.startsWith('--node_options=')) {
        // Let users pass through arguments to node itself
        nodeOptions.push(arg.slice('--node_options='.length))
    } else {
        // Remaining argv is collected to pass to the program
        args.push(arg)
    }
}

// ==============================================================================
// Run the main program
// ==============================================================================

const expectedExitCode = process.env.JS_BINARY__EXPECTED_EXIT_CODE

// If possible, we go straight to the entry point without exec'ing node again. However, we
// need to re-launch node if expected_exit_code is used, if we set any environment variables
// that affect node at startup, or if we are using any node options that were not already set
// on the current process.
const runInProcess =
    !ENV_CONFIGURES_NODE_STARTUP &&
    !expectedExitCode &&
    nodeOptions.length === STUB_NODE_OPTIONS.length &&
    nodeOptions.every((option, i) => option === STUB_NODE_OPTIONS[i])

if (runInProcess) {
    if (process.env.JS_BINARY__LOG_INFO) {
        logInfo(['running in this process', entryPoint, ...args].join(' '))
    }

    process.argv = [process.argv[0], entryPoint, ...args]

    // node itself was only given STUB_NODE_OPTIONS, because the preload is required below
    // rather than passed on a command line. Report the arguments the exec path would have
    // used: the preload reads its own location out of execArgv[1], and a tool forwarding
    // execArgv to a child still reproduces the patched runtime.
    process.execArgv = ['--require', launcher, ...nodeOptions]

    // The same per-launch setup node would have run as its first --require on the exec path:
    // execroot, the remaining validations, PATH, JS_BINARY__NODE_PATCHES, the logs, the fs
    // patches, and the chdir option. It is required here rather than passed to the stub
    // because it reads JS_BINARY__ variables that only exist once the launcher above has run.
    require(launcher)

    // A worker thread is started with the exec arguments node itself was given, which on this
    // path carry no --require at all -- the preload above was reached by require(), not by a
    // command line. Without this a worker would run with unpatched fs, where on the exec path
    // it would have re-run the preload and returned early with the bootstrap applied. A
    // program that asks for its own exec arguments is left alone.
    const workerThreads = require('node:worker_threads')
    const RealWorker = workerThreads.Worker
    // The node options too, not just the bootstrap: on the exec path a worker inherits node's
    // whole command line, so dropping them here would lose --preserve-symlinks-main and let a
    // worker's entry point resolve out of the runfiles tree (aspect-build/rules_js#362).
    const workerExecArgv = [
        '--require',
        process.env.JS_BINARY__NODE_PATCHES,
        ...nodeOptions,
    ]
    workerThreads.Worker = class Worker extends RealWorker {
        constructor(filename, options) {
            super(
                filename,
                options && options.execArgv
                    ? options
                    : { ...options, execArgv: workerExecArgv }
            )
        }
    }

    // Runs the entry point as the main module, so that `require.main === module` holds for
    // it. This returns as soon as the entry point's top level does; node then exits on its
    // own once the event loop drains, exactly as it would have on the exec path. Nothing may
    // follow it here -- an exit would truncate every asynchronous program.
    require('node:module').runMain()
} else {
    // We invoke node directly rather than through JS_BINARY__NODE_WRAPPER. This
    // way we avoid spawning an extra bash process on every launch. The wrapper is
    // still put on the PATH as `node` so that child processes get the patched
    // runtime.

    const nodeArgs = [
        '--require',
        launcher,
        ...nodeOptions,
        '--',
        entryPoint,
        ...args,
    ]

    if (process.env.JS_BINARY__LOG_INFO) {
        logInfo(['running', process.env.JS_BINARY__NODE_BINARY, ...nodeArgs].join(' '))
    }

    if (!expectedExitCode) {
        // Nothing must run after node exits, so replace this process with node.
        // Signals and terminal control are then delivered directly to node instead
        // of being proxied through a child process, and no launcher process is left
        // behind.
        //
        // process.execve is POSIX-only and was added in Node 22.15; when it is
        // unavailable we fall through to spawning node below.
        if (typeof process.execve === 'function') {
            try {
                process.execve(
                    process.env.JS_BINARY__NODE_BINARY,
                    [process.env.JS_BINARY__NODE_BINARY, ...nodeArgs],
                    { ...process.env }
                )
            } catch (e) {
                logDebug(`process.execve failed (${e.message}); falling back to spawn`)
            }
        }
    }

    // Reached when this launcher has to outlive the program: an expected exit code has to be
    // compared against once the program is done, and a Node before 22.15, or any Node on
    // Windows, has no process.execve to replace this process with.
    const { spawn } = require('node:child_process')
    const child = spawn(process.env.JS_BINARY__NODE_BINARY, nodeArgs, {
        stdio: 'inherit',
    })

    // ==============================================================================
    // Wait for program to finish
    // ==============================================================================

    // Node does not forward termination signals to any child process, so the
    // signals are trapped and forwarded manually. The handlers are removed on the
    // first signal so that a second one terminates this launcher.
    function forwardSignal(signal) {
        return () => {
            process.removeAllListeners('SIGTERM')
            process.removeAllListeners('SIGINT')
            try {
                child.kill(signal)
            } catch {
                // the child already exited
            }
        }
    }
    process.on('SIGTERM', forwardSignal('SIGTERM'))
    process.on('SIGINT', forwardSignal('SIGINT'))

    // Ends this process the way node ended, so that callers see a signal-terminated
    // process rather than an interposed 128+N exit code. That is what they would
    // have seen had this launcher been able to exec node instead of spawning it.
    function reraiseSignal(signal, exitCode) {
        logDebug(`exit code: ${exitCode}`)
        // Removing the last listener restores node's default disposition for the
        // signal, so killing ourselves with it now terminates this process.
        process.removeAllListeners('SIGTERM')
        process.removeAllListeners('SIGINT')
        process.kill(process.pid, signal)
        // Only reached if the signal turned out not to be fatal after all.
        process.exit(exitCode)
    }

    child.on('error', (err) => {
        logFatal(
            `failed to spawn node binary '${process.env.JS_BINARY__NODE_BINARY}': ${err.message}`
        )
        exitWith(127)
    })

    child.on('exit', (code, signal) => {
        const result =
            signal !== null && signal !== undefined
                ? 128 + (os.constants.signals[signal] || 0)
                : code

        // ==============================================================================
        // Mop up after main program
        // ==============================================================================

        if (expectedExitCode) {
            if (String(result) !== String(expectedExitCode)) {
                logError(
                    `expected exit code to be '${expectedExitCode}', but got '${result}'`
                )
                if (result === 0) {
                    // This exit code is handled specially by Bazel:
                    // https://github.com/bazelbuild/bazel/blob/486206012a664ecb20bdb196a681efc9a9825049/src/main/java/com/google/devtools/build/lib/util/ExitCode.java#L44
                    const BAZEL_EXIT_TESTS_FAILED = 3
                    exitWith(BAZEL_EXIT_TESTS_FAILED)
                }
                exitWith(result)
            } else {
                exitWith(0)
            }
        }

        if (signal) {
            reraiseSignal(signal, result)
        } else {
            exitWith(result)
        }
    })
}
