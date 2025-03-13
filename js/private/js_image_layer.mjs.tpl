import { readdir, readFile, readlink, writeFile } from 'node:fs/promises'
import { createWriteStream, link } from "node:fs"
import * as path from 'node:path'

const MTIME = "0"
const MODE_FOR_DIR = "0755"
const MODE_FOR_FILE = "0555"
const MODE_FOR_SYMLINK = "0775"


/**
 * @typedef {{
 *	 is_source: boolean
 *	 is_directory: boolean
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
    const found = entries[value];
    if (!found) {
        return undefined
    } else if (!found.skip) {
        // matched against the real entry. 
        return undefined
    }
    return found.dest
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
        throw e
    }
}

const EXECROOT = process.cwd();

// Resolve symlinks while staying inside the sandbox.
async function resolveSymlink(p) {
    let prevHop = path.resolve(p)
    let hopped = false
    while (true) {
        // /output-base/sandbox/4/execroot/wksp/bazel-out
        // /output-base/execroot/wksp/bazel-out
        let nextHop = await readlinkSafe(prevHop)
        // if the next hop leads to out of execroot, that means
        // we hopped too far, return the previous hop.

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

async function* walk(dir, accumulate = '') {
    const dirents = await readdir(dir, { withFileTypes: true })
    for (const dirent of dirents) {
        let isDirectory = dirent.isDirectory()

        if (
            dirent.isSymbolicLink() &&
            !dirent.isDirectory() &&
            !dirent.isFile()
        ) {
            // On OSX we sometimes encounter this bug: https://github.com/nodejs/node/issues/30646
            // The entry is apparently a symlink, but it's ambiguous whether it's a symlink to a
            // file or to a directory, and lstat doesn't tell us either. Determine the type by
            // attempting to read it as a directory.

            try {
                await readdir(path.join(dir, dirent.name))
                isDirectory = true
            } catch (error) {
                if (error.code === 'ENOTDIR') {
                    isDirectory = false
                } else {
                    throw error
                }
            }
        }

        if (isDirectory) {
            yield* walk(
                path.join(dir, dirent.name),
                path.join(accumulate, dirent.name)
            )
        } else {
            yield path.join(accumulate, dirent.name)
        }
    }
}

function add_parents(
	mtree,
    dest,
    uid, 
	gid,
) {
    const segments = path.dirname(dest).split('/')
    let prev = ''
    for (const part of segments) {
        if (!part) {
            continue
        }
        prev = path.join(prev, part)
		mtree.add(_mtree_line(
			prev,
			"dir",
			uid,
			gid,
			MTIME,
			// this is an intermediate directory and bazel does not allow specifying
        	// the file mode for intermediate directories so we use a static mode.
			MODE_FOR_DIR,
		))
    }
}


function vis(str) {
    let result = "";
    for (const char of Buffer.from(str)) {
      if (char < 32 || char > 126) { // Non-printable
        result += "\\" + char.toString(8).padStart(3, "0");
      } else {
        result += String.fromCharCode(char);
      }
    }
    return result;
}

function normalize(dest) {
    if (!dest.startsWith(".")) {
        if (!dest.startsWith("/")) {
            dest = "/" + dest;
        }
        dest = "." + dest;
    }

    return vis(dest)
}

function _mtree_line(
	dest,
	type,
	uid,
	gid,
	time,
	mode,
	content = null,
	link = null,
  ) {
	// mtree expects paths to start with ./ so normalize paths that starts with
	// `/` or relative path (without / and ./)
	dest = normalize(dest)
  
	const spec = [
	  dest,
	  "uid=" + uid,
	  "gid=" + gid,
	  "time=" + time,
	  "mode=" + mode,
	  "type=" + type,
	];
	if (content) {
	  spec.push("content=" + content);
	}
	if (type == "link") {
        link = normalize(link)
		const link_parent = path.dirname(dest)
		spec.push("link=" + path.relative(link_parent, link));
	}
	return spec.join(" ");
  }


async function split() {	
    const UID = "{{UID}}"
    const GID = "{{GID}}"
    const RUNFILES_DIR = "{{RUNFILES_DIR}}"
    const REPO_NAME = "{{REPO_NAME}}"

    // TODO: use computed_substitutions when we only support >= Bazel 7
    const entries = JSON.parse((await readFile("{{ENTRIES}}")).toString())

    {{VARIABLES}}

    for (const key of Object.keys(entries).sort()) {
        const {
            dest,
            is_directory,
            is_source,
            is_external,
            root,
            skip,
            repo_name
        } = entries[key]

        if (skip) {
            continue
        }

     	/** @type Set<string> */
        let mtree = null
        

        {{PICK_STATEMENTS}}
  

        // its a treeartifact. expand it and add individual entries.
        if (is_directory) {
            for await (const sub_key of walk(dest)) {
                const new_key = path.join(key, sub_key)
                const new_dest = path.join(dest, sub_key)

				add_parents(mtree, new_key, UID, GID)
				mtree.add(_mtree_line(
					new_key,
					"file",
					UID,
					GID,
					MTIME,
					MODE_FOR_FILE,
					new_dest
				))
            }
            continue
        }

        // create parents of current path.
        add_parents(mtree, key, UID, GID)

        // A source file from workspace, not an output of a target.
        if (is_source) {
			mtree.add(_mtree_line(
				key,
				"file",
				UID,
				GID,
				MTIME,
				MODE_FOR_FILE,
				dest
			))
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

        const realp = await resolveSymlink(dest)
        // it's important that we don't treat any symlink pointing out of execroot since
        // bazel symlinks external files into sandbox to make them available to us.
        if (realp && !is_external) {
            const output_path = realp.slice(realp.indexOf(root))
            // Look in all entries for symlinks since they may be in other layers
            let linkname = findKeyByValue(entries, output_path)


            // First party dependencies are linked against a folder in output tree or source tree
            // which means that we won't have an exact match for it in the entries. We could continue
            // doing what we have done https://github.com/aspect-build/rules_js/commit/f83467ba91deb88d43fd4ac07991b382bb14945f
            // but that is expensive and does not scale.
            if (linkname == undefined && !repo_name) {
                linkname = RUNFILES_DIR + "/" + REPO_NAME + realp.slice(realp.indexOf(root) + root.length)
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
            
			mtree.add(_mtree_line(
				key,
				"link",
				UID,
				GID,
				MTIME,
				// interestingly, bazel 5 and 6 sets different mode bits on symlinks.
				// well use `0o755` to allow owner&group to `rwx` and others `rx`
				// see: https://chmodcommand.com/chmod-775/
				MODE_FOR_SYMLINK,
				null,
				linkname
			))
        } else {
            mtree.add(_mtree_line(
				key,
				"file",
				UID,
				GID,
				MTIME,
                // Due to filesystems setting different bits depending on the os we have to opt-in
                // to use a stable mode for files.
                // In the future, we might want to hand off fine-grained control of these to users
                // see: https://chmodcommand.com/chmod-0555/
				MODE_FOR_FILE,
				dest
			))
        }
    }

    await Promise.all([
       {{WRITE_STATEMENTS}}
    ])

    
}

split()
