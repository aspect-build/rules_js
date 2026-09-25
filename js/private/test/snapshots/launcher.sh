#!/usr/bin/env bash

# This bash script is a wrapper around the NodeJS JavaScript file
# entry point with the following bazel label:
#     @@//js/private/test:shellcheck.js
#
# The script's was generated to execute the js_binary target
#     @@//js/private/test:shellcheck_launcher
#
# The template used to generate this script is
#     @@//js/private:js_binary.sh.tpl

set -o pipefail -o errexit -o nounset

export JS_BINARY__BINDIR="bazel-out/k8-fastbuild/bin"
export JS_BINARY__COMPILATION_MODE="fastbuild"
export JS_BINARY__TARGET_CPU="k8"
export JS_BINARY__BUILD_FILE_PATH="js/private/test/BUILD.bazel"
export JS_BINARY__PACKAGE="js/private/test"
export JS_BINARY__TARGET_NAME="shellcheck_launcher"
export JS_BINARY__TARGET="//js/private/test:shellcheck_launcher"
export JS_BINARY__WORKSPACE="_main"
if [[ -z "${JS_BINARY__PATCH_NODE_FS:-}" ]]; then export JS_BINARY__PATCH_NODE_FS="1"; fi
export JS_BINARY__COPY_DATA_TO_BIN="1"
if [[ -z "${JS_BINARY__LOG_FATAL:-}" ]]; then export JS_BINARY__LOG_FATAL="1"; fi
if [[ -z "${JS_BINARY__LOG_ERROR:-}" ]]; then export JS_BINARY__LOG_ERROR="1"; fi

# ==============================================================================
# Handle --bazel-bindir flag
# ==============================================================================

# If a --bazel-bindir <path> flag is passed it must be the first two
# arguments. It is consumed by this launcher script and used to set
# BAZEL_BINDIR, overriding any value already set in the environment.
if [ $# -gt 0 ] && [ "$1" = "--bazel-bindir" ]; then
    if [ $# -lt 2 ]; then
        echo "ERROR: --bazel-bindir flag requires a value" >&2
        exit 1
    fi
    BAZEL_BINDIR="$2"
    export BAZEL_BINDIR
    shift 2
fi

# ==============================================================================
# Prepare stdout capture, stderr capture && logging
# ==============================================================================

# Convert stdout, stderr and exit_code capture outputs paths to absolute paths.
# A path not starting with "bazel-out/" is relative to the bin directory; joining
# it with BAZEL_BINDIR here (rather than baking in bazel-out/<config>/bin at
# analysis time) keeps it correct when path mapping is active. This must happen
# before any directory changes below since it resolves against $PWD.
function resolve_capture_path {
    case "$1" in
    bazel-out/*) echo "$PWD/$1" ;;
    *) echo "$PWD/$BAZEL_BINDIR/$1" ;;
    esac
}

# TODO(4.0): remove support for capturing stderr, stdout, and exit code. The
# js_run_binary macro now handles this in a way that does not require help from
# the launcher.
if [ "${JS_BINARY__STDOUT_OUTPUT_FILE:-}" ]; then
    JS_BINARY__STDOUT_OUTPUT_FILE="$(resolve_capture_path "$JS_BINARY__STDOUT_OUTPUT_FILE")"
fi
if [ "${JS_BINARY__STDERR_OUTPUT_FILE:-}" ]; then
    JS_BINARY__STDERR_OUTPUT_FILE="$(resolve_capture_path "$JS_BINARY__STDERR_OUTPUT_FILE")"
fi
if [ "${JS_BINARY__EXIT_CODE_OUTPUT_FILE:-}" ]; then
    JS_BINARY__EXIT_CODE_OUTPUT_FILE="$(resolve_capture_path "$JS_BINARY__EXIT_CODE_OUTPUT_FILE")"
fi

# A stream with a declared output file is written straight to that file so that
# nothing has to run after node exits and this shell can exec node.
#
# A stream that is only subject to silent_on_success has no final destination, so
# it is buffered in a temp file and replayed on failure.
if [ "${JS_BINARY__STDOUT_OUTPUT_FILE:-}" ]; then
    STDOUT_CAPTURE="$JS_BINARY__STDOUT_OUTPUT_FILE"
elif [ "${JS_BINARY__SILENT_ON_SUCCESS:-}" ]; then
    STDOUT_CAPTURE=$(mktemp)
    STDOUT_CAPTURE_IS_TEMP=1
fi

if [ "${JS_BINARY__STDERR_OUTPUT_FILE:-}" ]; then
    STDERR_CAPTURE="$JS_BINARY__STDERR_OUTPUT_FILE"
elif [ "${JS_BINARY__SILENT_ON_SUCCESS:-}" ]; then
    STDERR_CAPTURE=$(mktemp)
    STDERR_CAPTURE_IS_TEMP=1
fi

# FATAL and ERROR diagnostics from this launcher only go into the stderr capture
# if that capture is a temp file that will get replayed on failure. Otherwise,
# we write these straight to stderr so that they do not get lost if the action
# fails.
LOG_ERROR_CAPTURE="${STDERR_CAPTURE_IS_TEMP:+$STDERR_CAPTURE}"

export JS_BINARY__LOG_PREFIX="aspect_rules_js[js_binary]"

# Emit a log line to $1, or to the real stderr when $1 is empty.
function log_to {
    local capture="$1"
    local level="$2"
    local message="$3"
    if [ "$capture" ]; then
        printf "%s: %s: %s\n" "$level" "$JS_BINARY__LOG_PREFIX" "$message" >>"$capture"
    else
        printf "%s: %s: %s\n" "$level" "$JS_BINARY__LOG_PREFIX" "$message" >&2
    fi
}

function log_fatal {
    if [ "${JS_BINARY__LOG_FATAL:-}" ]; then
        log_to "${LOG_ERROR_CAPTURE:-}" FATAL "$1"
    fi
}

function log_error {
    if [ "${JS_BINARY__LOG_ERROR:-}" ]; then
        log_to "${LOG_ERROR_CAPTURE:-}" ERROR "$1"
    fi
}

function log_info {
    if [ "${JS_BINARY__LOG_INFO:-}" ]; then
        log_to "${STDERR_CAPTURE:-}" INFO "$1"
    fi
}

function log_debug {
    if [ "${JS_BINARY__LOG_DEBUG:-}" ]; then
        log_to "${STDERR_CAPTURE:-}" DEBUG "$1"
    fi
}

_exit() {
    EXIT_CODE=$?

    # Streams captured to a declared output file were written there directly and
    # need no mop up. Only the temp files that back silent_on_success do.
    if [ "${STDERR_CAPTURE_IS_TEMP:-}" ]; then
        if [ "$EXIT_CODE" != 0 ] || [ -z "${JS_BINARY__SILENT_ON_SUCCESS:-}" ]; then
            cat "$STDERR_CAPTURE" >&2
        fi
        rm "$STDERR_CAPTURE"
    fi

    if [ "${STDOUT_CAPTURE_IS_TEMP:-}" ]; then
        if [ "$EXIT_CODE" != 0 ] || [ -z "${JS_BINARY__SILENT_ON_SUCCESS:-}" ]; then
            cat "$STDOUT_CAPTURE"
        fi
        rm "$STDOUT_CAPTURE"
    fi

    log_debug "exit code: $EXIT_CODE"

    exit "$EXIT_CODE"
}

trap _exit EXIT

# ==============================================================================
# Initialize RUNFILES environment variable
# ==============================================================================

# It helps to determine if we are running on a Windows environment (excludes WSL as it acts like Unix)
case "$(uname -s)" in
CYGWIN*) _IS_WINDOWS=1 ;;
MINGW*) _IS_WINDOWS=1 ;;
MSYS_NT*) _IS_WINDOWS=1 ;;
*) _IS_WINDOWS=0 ;;
esac

# It helps to normalizes paths when running on Windows.
#
# Example:
# C:/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C -> /c/Users/XUser/_bazel_XUser/7q7kkv32/execroot/A/b/C
function _normalize_path {
    if [ "$_IS_WINDOWS" -eq "1" ]; then
        # Apply the followings paths transformations to normalize paths on Windows
        # -process driver letter
        # -convert path separator
        sed -e 's#^\(.\):#/\L\1#' -e 's#\\#/#g' <<<"$1"
    else
        echo "$1"
    fi
    return
}

# Set a RUNFILES environment variable to the root of the runfiles tree
# since RUNFILES_DIR is not set by Bazel in all contexts.
# For example, `RUNFILES=/path/to/my_js_binary.sh.runfiles`.
#
# Call this program X. X was generated by a genrule and may be invoked
# in many ways:
#   1a) directly by a user, with $0 in the output tree
#   1b) via 'bazel run' (similar to case 1a)
#   2) directly by a user, with $0 in X's runfiles
#   3) by another program Y which has a data dependency on X, with $0 in Y's
#      runfiles
#   4a) via 'bazel test'
#   4b) case 3 in the context of a test
#   5a) by a genrule cmd, with $0 in the output tree
#   6a) case 3 in the context of a genrule
#
# For case 1, $0 will be a regular file, and the runfiles will be
# at $0.runfiles.
# For case 2 or 3, $0 will be a symlink to the file seen in case 1.
# For case 4, $TEST_SRCDIR should already be set to the runfiles by
# blaze.
# Case 5a is handled like case 1.
# Case 6a is handled like case 3.
if [ "${TEST_SRCDIR:-}" ]; then
    # Case 4, bazel has identified runfiles for us.
    RUNFILES=$(_normalize_path "$TEST_SRCDIR")
elif [ "${RUNFILES_MANIFEST_FILE:-}" ]; then
    RUNFILES=$(_normalize_path "$RUNFILES_MANIFEST_FILE")
    if [[ "${RUNFILES}" == *.runfiles_manifest ]]; then
        # Bazel puts the manifest besides the runfiles with the suffix .runfiles_manifest.
        # For example, the runfiles directory is named my_binary.runfiles then the manifest is beside the
        # runfiles directory and named my_binary.runfiles_manifest
        RUNFILES=${RUNFILES%_manifest}
    elif [[ "${RUNFILES}" == */MANIFEST ]]; then
        # Bazel for windows puts the manifest file named MANIFEST in the runfiles directory
        RUNFILES=${RUNFILES%/MANIFEST}
    else
        log_fatal "Unexpected RUNFILES_MANIFEST_FILE value $RUNFILES_MANIFEST_FILE"
        exit 1
    fi
else
    case "$0" in
    /*) self="$0" ;;
    *) self="$PWD/$0" ;;
    esac
    while true; do
        if [ -e "$self.runfiles" ]; then
            RUNFILES="$self.runfiles"
            break
        fi

        if [[ "$self" == *.runfiles/* ]]; then
            RUNFILES="${self%%.runfiles/*}.runfiles"
            # don't break; this is a last resort for case 6b
        fi

        if [ ! -L "$self" ]; then
            break
        fi

        readlink="$(readlink "$self")"
        if [[ "$readlink" == /* ]]; then
            self="$readlink"
        else
            # resolve relative symlink
            self="${self%%/*}/$readlink"
        fi
    done

    if [ -z "${RUNFILES:-}" ]; then
        log_fatal "RUNFILES environment variable is not set"
        exit 1
    fi

    RUNFILES=$(_normalize_path "$RUNFILES")
fi
if [ "${RUNFILES:0:1}" != "/" ]; then
    # Ensure RUNFILES set above is an absolute path. It may be a path relative
    # to the PWD in case where RUNFILES_MANIFEST_FILE is used above.
    RUNFILES="$PWD/$RUNFILES"
fi
# Set RUNFILES_DIR if not already set so that tools such as @bazel/runfiles
# can locate runfiles without requiring RUNFILES to be exported.
export RUNFILES_DIR="${RUNFILES_DIR:-$RUNFILES}"

JS_BINARY__RUNFILES="$RUNFILES"
export JS_BINARY__RUNFILES

# ==============================================================================
# Prepare to run main program
# ==============================================================================

# The execroot the entry point is resolved against below. A parent js_binary process hands its
# own down when it asks for an execroot entry point, because the entry point it resolved is in
# that tree; otherwise this script was started in it. Nothing else here needs an execroot: the
# launcher preload works out JS_BINARY__EXECROOT for the program and everything it spawns.
if [ "${JS_BINARY__USE_EXECROOT_ENTRY_POINT:-}" ] && [ "${JS_BINARY__EXECROOT:-}" ]; then
    execroot="$JS_BINARY__EXECROOT"
else
    execroot="$PWD"
fi

# Build actions are started in the execroot, so change into the root of the Bazel output tree,
# which is where js_binary programs run. See
# https://github.com/aspect-build/rules_js/tree/dbb5af0d2a9a2bb50e4cf4a96dbc582b27567155#running-nodejs-programs
# for more context on why we do this. It cannot wait for the preload: node resolves the bare
# specifier of a --require in node_options against the directory it was started in.
#
# The bindir is only there to change into when this really is an execroot; in a runfiles tree,
# or in a nested js_binary already running in the bindir, there is nothing to do. The preload
# tells those apart from the broken case by JS_BINARY__CHANGED_TO_BINDIR.
if [ -z "${JS_BINARY__NO_CD_BINDIR:-}" ] && [ "${BAZEL_BINDIR:-}" ] && [ -d "$BAZEL_BINDIR" ]; then
    log_debug "changing directory to BAZEL_BINDIR (root of Bazel output tree) $BAZEL_BINDIR"
    export JS_BINARY__CHANGED_TO_BINDIR=1
    cd "$BAZEL_BINDIR"
fi

if [ "${JS_BINARY__USE_EXECROOT_ENTRY_POINT:-}" ] && [ -z "${BAZEL_BINDIR:-}" ]; then
    log_fatal "Expected BAZEL_BINDIR to be set when JS_BINARY__USE_EXECROOT_ENTRY_POINT is set"
    exit 1
fi

function resolve_execroot_bin_path {
    local short_path="$1"
    if [[ "$short_path" == ../* ]]; then
        echo "$execroot/$BAZEL_BINDIR/external/${short_path:3}"
    else
        echo "$execroot/$BAZEL_BINDIR/$short_path"
    fi
}

function resolve_execroot_src_path {
    local short_path="$1"
    if [[ "$short_path" == ../* ]]; then
        echo "$execroot/external/${short_path:3}"
    else
        echo "$execroot/$short_path"
    fi
}

# Resolve a toolchain file that is a file of this workspace or another repository
# in the runfiles tree, or an absolute path a user set in node_toolchain.
function resolve_toolchain_path {
    local file
    file="$(_normalize_path "$1")"
    if [ "${file:0:1}" = "/" ]; then
        echo "$file"
    elif [ "${JS_BINARY__NO_RUNFILES:-}" ]; then
        resolve_execroot_src_path "$file"
    else
        echo "$JS_BINARY__RUNFILES/_main/$file"
    fi
}

# Everything below is resolved here only because node needs it on its command line
# or bash needs it to start node at all. The checks that can wait, and the rest of
# the environment the program sees, are done by the launcher preload once node is up.

if [ "${JS_BINARY__USE_EXECROOT_ENTRY_POINT:-}" ] || [ "${JS_BINARY__NO_RUNFILES:-}" ]; then
    entry_point=$(resolve_execroot_bin_path "js/private/test/shellcheck.js")
else
    entry_point="$JS_BINARY__RUNFILES/_main/js/private/test/shellcheck.js"
fi

export JS_BINARY__NODE_BINARY
JS_BINARY__NODE_BINARY=$(resolve_toolchain_path "../rules_nodejs++node+nodejs_linux_amd64/bin/nodejs/bin/node")
if [ ! -f "$JS_BINARY__NODE_BINARY" ]; then
    log_fatal "node binary '$JS_BINARY__NODE_BINARY' not found"
    exit 1
fi
if [ "$_IS_WINDOWS" -ne "1" ] && [ ! -x "$JS_BINARY__NODE_BINARY" ]; then
    log_fatal "node binary '$JS_BINARY__NODE_BINARY' is not executable"
    exit 1
fi

npm=""
if [ "$npm" ]; then
    export JS_BINARY__NPM_BINARY
    JS_BINARY__NPM_BINARY=$(resolve_toolchain_path "$npm")
fi

launcher=$(resolve_toolchain_path "js/private/node-bootstrap/launcher.cjs")
if [ ! -f "$launcher" ]; then
    log_fatal "launcher '$launcher' not found"
    exit 1
fi

# Gather node options
JS_BINARY__NODE_OPTIONS=()
JS_BINARY__NODE_OPTIONS+=("--preserve-symlinks-main")

ARGS=()
ALL_ARGS=("--my_arg" "$@")
for ARG in ${ALL_ARGS[@]+"${ALL_ARGS[@]}"}; do
    case "$ARG" in
    # Let users pass through arguments to node itself
    --node_options=*) JS_BINARY__NODE_OPTIONS+=("${ARG#--node_options=}") ;;
    # Remaining argv is collected to pass to the program
    *) ARGS+=("$ARG") ;;
    esac
done

# ==============================================================================
# Run the main program
# ==============================================================================

# Invoke node directly rather than through $JS_BINARY__NODE_WRAPPER. This way
# we avoid spawning an extra bash process on every launch. The wrapper is
# still put on the PATH as `node` so that child processes get the patched
# runtime.
node_cmd=("$JS_BINARY__NODE_BINARY" --require "$launcher")

if [ "${JS_BINARY__LOG_INFO:-}" ]; then
    log_info "$(echo -n "running" "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"})"
fi

# De-export capture-related vars so child processes (e.g. a nested js_binary)
# do not inherit them. The bash script has already consumed them above to set up
# STDOUT_CAPTURE / STDERR_CAPTURE; leaking them would cause a nested js_binary
# to silently swallow its own stdout or write to the wrong output file.
# export -n keeps the value accessible to the _exit trap while removing it from
# the environment seen by node and any processes it spawns.
export -n JS_BINARY__STDOUT_OUTPUT_FILE JS_BINARY__STDERR_OUTPUT_FILE JS_BINARY__EXIT_CODE_OUTPUT_FILE JS_BINARY__SILENT_ON_SUCCESS

set +e

if [ -z "${JS_BINARY__EXPECTED_EXIT_CODE:-}" ] && [ -z "${JS_BINARY__EXIT_CODE_OUTPUT_FILE:-}" ] &&
    [ -z "${STDOUT_CAPTURE_IS_TEMP:-}" ] && [ -z "${STDERR_CAPTURE_IS_TEMP:-}" ]; then
    # Nothing must run after node exits, so replace this shell with node. Signals
    # and terminal control are then delivered directly to node instead of being
    # proxied through a backgrounded child.
    if [ "${STDOUT_CAPTURE:-}" ]; then
        exec 1>>"$STDOUT_CAPTURE"
    fi
    if [ "${STDERR_CAPTURE:-}" ]; then
        exec 2>>"$STDERR_CAPTURE"
    fi
    exec "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"}
    exit 127
fi

if [ "${STDOUT_CAPTURE:-}" ] && [ "${STDERR_CAPTURE:-}" ]; then
    "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"} <&0 >>"$STDOUT_CAPTURE" 2>>"$STDERR_CAPTURE" &
elif [ "${STDOUT_CAPTURE:-}" ]; then
    "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"} <&0 >>"$STDOUT_CAPTURE" &
elif [ "${STDERR_CAPTURE:-}" ]; then
    "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"} <&0 2>>"$STDERR_CAPTURE" &
else
    "${node_cmd[@]}" ${JS_BINARY__NODE_OPTIONS[@]+"${JS_BINARY__NODE_OPTIONS[@]}"} -- "$entry_point" ${ARGS[@]+"${ARGS[@]}"} <&0 &
fi

# ==============================================================================
# Wait for program to finish
# ==============================================================================

readonly child=$!
# Bash does not forward termination signals to any child process when
# running in docker, so we need to manually trap and forward the signals.
#
# Each trap is reset as it fires, so that a repeat of that signal terminates this
# script rather than being swallowed.
_term() { trap - SIGTERM; kill -TERM "${child}" 2>/dev/null; }
_int() { trap - SIGINT; kill -INT "${child}" 2>/dev/null; }
trap _term SIGTERM
trap _int SIGINT

# A wait returns as soon as a trapped signal has been handled, whether or not the
# child has exited, so keep waiting until it has.
wait "$child"
RESULT="$?"
while kill -0 "$child" 2>/dev/null; do
    wait "$child"
    RESULT="$?"
done

# Remove traps now that the child process has exited
trap - SIGTERM SIGINT
set -e

# ==============================================================================
# Mop up after main program
# ==============================================================================

if [ "${JS_BINARY__EXPECTED_EXIT_CODE:-}" ]; then
    if [ "$RESULT" != "$JS_BINARY__EXPECTED_EXIT_CODE" ]; then
        log_error "expected exit code to be '$JS_BINARY__EXPECTED_EXIT_CODE', but got '$RESULT'"
        if [ $RESULT -eq 0 ]; then
            # This exit code is handled specially by Bazel:
            # https://github.com/bazelbuild/bazel/blob/486206012a664ecb20bdb196a681efc9a9825049/src/main/java/com/google/devtools/build/lib/util/ExitCode.java#L44
            readonly BAZEL_EXIT_TESTS_FAILED=3
            exit $BAZEL_EXIT_TESTS_FAILED
        fi
        exit $RESULT
    else
        exit 0
    fi
fi

if [ "${JS_BINARY__EXIT_CODE_OUTPUT_FILE:-}" ]; then
    # Exit zero if the exit code was captured
    echo -n "$RESULT" >"$JS_BINARY__EXIT_CODE_OUTPUT_FILE"
    exit 0
else
    exit $RESULT
fi
