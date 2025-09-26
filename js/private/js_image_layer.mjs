import { readdir, readFile, readlink, writeFile } from 'node:fs/promises'
import { createWriteStream } from 'node:fs'
import * as path from 'node:path'

/**
 * @typedef {{
 *	 is_source: boolean
 *: boolean
 *	 is_external: boolean
 *	 dest: string
 *	 root?: string
 *	 skip?: boolean
 *   repo_name?: string
 * }} Entry
 * @typedef {{ [path: string]: Entry }} Entries
 * @typedef {Map<string, {match: RegExp, unused_inputs: string, mtree: string }>} LayerGroup
 */

/**
 * @param {Entry} entries
 * @param {string} value
 * @returns {string | undefined}
 */
function findKeyByValue(entries, value) {
    const found = entries[value]
    if (!found) {
        return undefined
    } else if (typeof found != 'string') {
        // matched against the real entry.
        return undefined
    }
    return found
}

async function readlinkSafe(p) {
    try {
        const link = await readlink(p)
        return path.resolve(path.dirname(p), link)
    } catch (e) {
        if (e.code == 'EINVAL') {
            return p
        }
        if (e.code == 'ENOENT') {
            // That is as far as we can follow this symlink in this layer so we can only
            // assume the file exists in another layer
            return p
        }
        if (process.platform === 'win32' && e.code == 'UNKNOWN' && e.errno == -4094) {
            // Windows returns 'UNKNOWN' when reading a link that is a file
            return p
        }
        throw e
    }
}

const EXECROOT = process.cwd().replace(/\\/g, '/')

// Resolve symlinks while staying inside the sandbox.
async function resolveSymlink(p) {
    let prevHop = path.posix.resolve(p)
    let hopped = false
    while (true) {
        // /output-base/sandbox/4/execroot/wksp/bazel-out
        // /output-base/execroot/wksp/bazel-out
        let nextHop = await readlinkSafe(prevHop)
        // if the next hop leads to out of execroot, that means
        // we hopped too far, return the previous hop.

        nextHop = nextHop.replace(/\\/g, '/')
        if (!nextHop.startsWith(EXECROOT)) {
            return hopped ? prevHop : undefined
        }

        // If there is more than one hop while staying inside sandbox
        // that means the symlink has multiple indirection within sandbox
        // but we want to hop only once, for example first party deps.
        //  -> js/private/test/image/node_modules/@mycorp/pkg-d
        //      -> ../../../../../../node_modules/.aspect_rules_js/@mycorp+pkg-d@0.0.0/node_modules/@mycorp/pkg-d    <- WE WANT TO STOP RIGHT HERE.
        //          -> ../../../../../../examples/npm_package/packages/pkg_d
        if (nextHop != prevHop && hopped) {
            return prevHop
        }

        // if the next hop is leads to a different path
        // that indicates a symlink
        if (nextHop != prevHop && !hopped) {
            prevHop = nextHop
            hopped = true
        } else if (!hopped) {
            return undefined
        } else {
            return nextHop
        }
    }
}

function add_parents(mtree, dest) {
    const segments = path.dirname(dest).split('/')
    let prev = ''
    for (const part of segments) {
        if (!part || part == '.') {
            continue
        }
        prev = path.posix.join(prev, part)
        mtree.add(_mtree_dir_line(prev))
    }
}

/**
 * @param {string} str
 * @returns {string}
 */
function vis(str) {
    let result = ''
    // There is no way to iterate over byte-by-byte UTF-8 characters in JS
    // so we have to use Buffer to get the bytes.
    // Rust has this https://doc.rust-lang.org/std/string/struct.String.html#method.as_bytes
    // and the equivalent in nodejs is Buffer.
    for (const char of Buffer.from(str)) {
        if (char == '\\') {
            throw new Error(
                `unexpected entry format. ${JSON.stringify(
                    str
                )}. find the source of the errant backslash`
            )
        }
        if (char < 33 || char > 126) {
            // Non-printable
            result += '\\' + char.toString(8).padStart(3, '0')
        } else {
            result += String.fromCharCode(char)
        }
    }
    return result
}

function _mtree_dir_line(dir) {
    const dest = vis(dir)
    // Due to filesystems setting different bits depending on the os we have to opt-in
    // to use a stable mode for files.
    return `./${dest} uid={{UID}} gid={{GID}} time=0 mode={{DIRECTORY_MODE}} type=dir`
}

function _mtree_link_line(key, linkname) {
    const link_parent = path.posix.dirname(key)
    linkname = path.posix.relative(link_parent, linkname)

    // interestingly, bazel 5 and 6 sets different mode bits on symlinks.
    // well use `0o755` to allow owner&group to `rwx` and others `rx`
    // see: https://chmodcommand.com/chmod-775/
    return `${vis(
        key
    )} uid={{UID}} gid={{GID}} time=0 mode=0775 type=link link=${vis(linkname)}`
}

function _mtree_file_line(key, content) {
    const dest = vis(key)
    // Due to filesystems setting different bits depending on the os we have to opt-in
    // to use a stable mode for files.
    return `${dest} uid={{UID}} gid={{GID}} time=0 mode={{FILE_MODE}} type=file content=${vis(
        content
    )}`
}

async function split() {
    const RUNFILES_DIR = '{{RUNFILES_DIR}}'
    const REPO_NAME = '{{REPO_NAME}}'

    // TODO: use computed_substitutions when we only support >= Bazel 7
    const entries = JSON.parse((await readFile('{{ENTRIES}}')).toString())

    const preserveSymlniksRe = new RegExp('{{PRESERVE_SYMLINKS}}')

    /*{{VARIABLES}}*/

    const resolveTasks = []
    const splitterUnusedInputs = createWriteStream('{{UNUSED_INPUTS}}')

    for (const key in entries) {
        if (typeof entries[key] == 'string') {
            continue
        }
        const { dest, is_source, is_external, root, repo_name } = entries[key]

        /** @type Set<string> */
        let mtree = null

        const destBuf = Buffer.from(dest + '\n')

        /*{{PICK_STATEMENTS}}*/

        // create parents of current path.
        add_parents(mtree, key)

        // A source file from workspace, not an output of a target.
        if (is_source) {
            mtree.add(_mtree_file_line(key, dest))
            // Splitter does not care about this file since its not a symlink, so prune it for better cache hit rate.
            splitterUnusedInputs.write(destBuf)
            continue
        }

        // root indicates where the generated source comes from. it looks like
        // `bazel-out/darwin_arm64-fastbuild` when there's no transition.
        if (!root) {
            // everything except sources should have
            throw new Error(
                `unexpected entry format. ${JSON.stringify(
                    entries[key]
                )}. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`
            )
        }

        // If its external or if it does not match the `preserve_symlinks` regex
        // we don't support preserving symlinks.
        if (is_external || !preserveSymlniksRe.test(key)) {
            // Just add the file as a regular file.
            mtree.add(_mtree_file_line(key, dest))
            // Splitter does not care about this file since its not a symlink, so prune it for better cache hit rate.
            splitterUnusedInputs.write(destBuf)
            continue
        }

        const resolveTask = resolveSymlink(dest).then((realp) => {
            // it's important that we don't treat any symlink pointing out of execroot since
            // bazel symlinks external files into sandbox to make them available to us.
            if (realp) {
                const output_path = realp.slice(realp.indexOf(root))
                // Look in all entries for symlinks since they may be in other layers
                let linkname = findKeyByValue(entries, output_path)

                // First party dependencies are linked against a folder in output tree or source tree
                // which means that we won't have an exact match for it in the entries. We could continue
                // doing what we have done https://github.com/aspect-build/rules_js/commit/f83467ba91deb88d43fd4ac07991b382bb14945f
                // but that is expensive and does not scale.
                if (linkname == undefined && !repo_name) {
                    linkname =
                        RUNFILES_DIR +
                        '/' +
                        REPO_NAME +
                        realp.slice(realp.indexOf(root) + root.length)
                }

                if (linkname == undefined) {
                    throw new Error(
                        `Couldn't map symbolic link ${output_path} to a path. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose\n\n` +
                            `dest: ${dest}\n` +
                            `realpath: ${realp}\n` +
                            `output_path: ${output_path}\n` +
                            `root: ${root}\n` +
                            `repo_name: ${repo_name}\n` +
                            `runfiles: ${key}\n\n`
                    )
                }
                // add the symlink to the mtree
                mtree.add(_mtree_link_line(key, linkname))
            } else {
                // If we can't resolve the symlink, we just add the file as a regular file.
                mtree.add(_mtree_file_line(key, dest))
                // Splitter does not care about this file since its not a symlink, so prune it for better cache hit rate.
                splitterUnusedInputs.write(destBuf)
            }
        })
        resolveTasks.push(resolveTask)
    }

    await Promise.all(resolveTasks)

    await Promise.all([
        /*{{WRITE_STATEMENTS}}*/
    ])
}

await split()
