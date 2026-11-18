"Bash snippets for js rules"

# Bash snippet to initialize the RUNFILES environment variable.
# Depends on there being a log_fatal function defined.
# NB: If this can be generalized fully in the future and not depend on log_fatal
# then it could be hoisted to bazel-lib where we have other bash snippets.
BASH_INITIALIZE_RUNFILES = r"""
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

# Marks a runfiles tree built from a manifest as complete.
_RUNFILES_TREE_COMPLETE=".js_binary_runfiles_complete"

# Builds the runfiles tree $3 from the manifest $1, in a temporary directory
# named $2.tmp.*.
#
# The tree is marked complete last and then renamed into place, so a launch
# that finds a marked $3 can use it as is, even while other launches race to
# build it. A $3 without the mark, such as one a cleaner of temporary files
# emptied, is replaced. Each entry costs one bash iteration: parent
# directories are made by one batched mkdir, and the symlinks of a directory
# whose names match their targets' names are made by one ln.
function _build_runfiles_tree {
    local manifest="$1" prefix="$2" tree="$3"
    (
        _fail() {
            log_fatal "$1"
            exit 1
        }
        if [ "$_IS_WINDOWS" -eq "1" ]; then
            # ln on MSYS and Cygwin copies files unless told to make native
            # symlinks. A copy would go stale when its source changes under the
            # same manifest, so fail instead. ln takes the Windows paths of the
            # manifest as they are, so they are not normalized.
            export MSYS="${MSYS:+$MSYS }winsymlinks:nativestrict"
            export CYGWIN="${CYGWIN:+$CYGWIN }winsymlinks:nativestrict"
        fi
        tmp=$(mktemp -d "$prefix.tmp.XXXXXX")
        trap 'rm -rf "$tmp"' EXIT

        keys=()
        targets=()
        dirs=()
        last_dir=""
        while IFS= read -r line || [ -n "$line" ]; do
            [ -z "$line" ] && continue
            raw=$line
            escaped=0
            if [ "${line:0:1}" = " " ]; then
                # Bazel starts a line with a space when the key or target holds a
                # space, newline or backslash; these are escaped as \s (key only),
                # \n and \b. Every literal backslash is written as \b, so a \s or
                # \n is never part of one and \b can be unescaped last.
                escaped=1
                line=${line:1}
            fi
            if [[ "$line" == *" "* ]]; then
                key=${line%% *}
                target=${line#* }
            else
                key=$line
                target=""
            fi
            if [ "$escaped" -eq "1" ]; then
                key=${key//\\s/ }
                key=${key//\\n/$'\n'}
                key=${key//\\b/\\}
                target=${target//\\n/$'\n'}
                target=${target//\\b/\\}
            fi
            if [ -z "$key" ]; then
                _fail "Malformed line in RUNFILES_MANIFEST_FILE $manifest: '$raw'"
            fi
            keys+=("$key")
            targets+=("$target")
            dir=${key%/*}
            if [ "$dir" != "$key" ] && [ "$dir" != "$last_dir" ]; then
                dirs+=("$dir")
                last_dir=$dir
            fi
        done <"$manifest"

        cd "$tmp" || exit 1
        if [ ${#dirs[@]} -gt 0 ]; then
            printf '%s\0' "${dirs[@]}" | xargs -0 mkdir -p
        fi

        # Pending targets for one `ln -s target... dir/`, capped well below ARG_MAX.
        group=()
        group_dir=""
        group_len=0
        i=0
        while [ "$i" -lt ${#keys[@]} ]; do
            key=${keys[$i]}
            target=${targets[$i]}
            i=$((i + 1))
            if [ -z "$target" ]; then
                # An empty file, such as an __init__.py Bazel adds to runfiles.
                : >"$key"
                continue
            fi
            if [ "${key##*/}" != "${target##*/}" ]; then
                ln -s "$target" "$key" || _fail "Cannot create runfiles symlink $tmp/$key"
                continue
            fi
            dir=${key%/*}
            [ "$dir" = "$key" ] && dir="."
            if [ ${#group[@]} -gt 0 ] && { [ "$dir" != "$group_dir" ] || [ "$group_len" -gt 65536 ]; }; then
                ln -s "${group[@]}" "$group_dir/" || _fail "Cannot create runfiles symlinks in $tmp/$group_dir"
                group=()
                group_len=0
            fi
            group_dir=$dir
            group+=("$target")
            group_len=$((group_len + ${#target}))
        done
        if [ ${#group[@]} -gt 0 ]; then
            ln -s "${group[@]}" "$group_dir/" || _fail "Cannot create runfiles symlinks in $tmp/$group_dir"
        fi

        : >"$_RUNFILES_TREE_COMPLETE"

        # Windows cannot rename the working directory of a process.
        cd /
        if [ -e "$tree" ]; then
            if [ -f "$tree/$_RUNFILES_TREE_COMPLETE" ]; then
                # Another launch built it first.
                exit 0
            fi
            # A partial tree: move it out of the way. Another launch replacing it
            # at the same time may have moved it already.
            partial=$(mktemp -d "$prefix.tmp.XXXXXX")
            mv "$tree" "$partial/" 2>/dev/null || true
            rm -rf "$partial"
        fi
        mv "$tmp" "$tree"
        # A launch that renamed its tree into place after the check above made mv
        # move this one into that tree instead; remove it from there.
        rm -rf "${tree:?}/${tmp##*/}"
    )
}

# Sets RUNFILES to a runfiles tree built from the manifest $1, for a manifest
# that has no runfiles directory next to it.
#
# Trees live in a per-user directory and are named after the path and the
# content of the manifest, so later launches with the same manifest reuse the
# tree instead of leaving a new one behind every time; this script ends in
# `exec`, so a trap could not remove a per-launch tree. Trees for earlier
# contents of a manifest are left to the cleaner of temporary files, since a
# process started from one may still be running.
function _runfiles_from_manifest {
    local manifest="$1" crc len path_sum content_sum base prefix
    # cksum prints "<crc> <length>" for its standard input. BSD cksum reads a
    # `-` argument as a file name, so each sum is taken from standard input.
    read -r crc len _ <<<"$(printf '%s' "$manifest" | cksum)"
    path_sum="${crc}_${len}"
    read -r crc len _ <<<"$(cksum <"$manifest")"
    content_sum="${crc}_${len}"
    base="$(_normalize_path "${TEST_TMPDIR:-${TMPDIR:-/tmp}}")/js_binary_runfiles.$UID"
    mkdir -m 700 "$base" 2>/dev/null || true
    if [ -L "$base" ] || [ ! -d "$base" ] || [ ! -O "$base" ]; then
        log_fatal "Cannot build a runfiles tree from RUNFILES_MANIFEST_FILE $manifest: $base is not a directory owned by the current user"
        exit 1
    fi
    prefix="$base/$path_sum"
    RUNFILES="$prefix.$content_sum"
    if [ ! -f "$RUNFILES/$_RUNFILES_TREE_COMPLETE" ]; then
        _build_runfiles_tree "$manifest" "$prefix" "$RUNFILES"
    fi
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
    _manifest=$(_normalize_path "$RUNFILES_MANIFEST_FILE")
    RUNFILES=""
    if [[ "${_manifest}" == *.runfiles_manifest ]]; then
        # Bazel puts the manifest besides the runfiles with the suffix .runfiles_manifest.
        # For example, the runfiles directory is named my_binary.runfiles then the manifest is beside the
        # runfiles directory and named my_binary.runfiles_manifest
        RUNFILES=${_manifest%_manifest}
    elif [[ "${_manifest}" == */MANIFEST ]]; then
        # Bazel for windows puts the manifest file named MANIFEST in the runfiles directory
        RUNFILES=${_manifest%/MANIFEST}
    fi
    if [ -z "${RUNFILES}" ] || [ ! -d "${RUNFILES}" ]; then
        # Manifest-only runfiles: build a runfiles tree from the manifest.
        if [ ! -f "${_manifest}" ]; then
            log_fatal "RUNFILES_MANIFEST_FILE $RUNFILES_MANIFEST_FILE does not exist"
            exit 1
        fi
        _runfiles_from_manifest "${_manifest}"
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
"""
