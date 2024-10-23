import * as path from 'node:path'
import * as perf_hooks from 'node:perf_hooks'
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as child_process from 'node:child_process'
import * as crypto from 'node:crypto'

// Globals
const RUNFILES_ROOT = path.join(
    process.env.JS_BINARY__RUNFILES,
    process.env.JS_BINARY__WORKSPACE
)
const syncedTime = new Map()
const syncedChecksum = new Map()
const mkdirs = new Set()

// Ensure that a directory exists. If it has not been previously created or does not exist then it
// creates the directory, first recursively ensuring that its parent directory exists. Intentionally
// synchronous to avoid race conditions between async promises. If we use `await fs.promises.mkdir(p)`
// then you could end up calling it twice in two different promises which
// would error on the 2nd call. This is because `if (!fs.existsSync(p))` followed by
// `await fs.promises.mkdir(p)` is not atomic so both promises can enter into the condition before
// either calls `mkdir`.
function mkdirpSync(p) {
    if (!p) {
        return
    }
    if (mkdirs.has(p)) {
        return
    }
    if (!fs.existsSync(p)) {
        mkdirpSync(path.dirname(p))
        fs.mkdirSync(p)
    }
    mkdirs.add(p)
}

// Determines if a file path refers to a node module.
// See js/private/test/js_run_devserver/js_run_devserver.spec.mjs for examples.
export function isNodeModulePath(p) {
    const parentDir = path.dirname(p)
    const parentDirName = path.basename(parentDir)

    if (parentDirName === 'node_modules') {
        // unscoped module like 'lodash'
        return true
    } else if (parentDirName.startsWith('@')) {
        // scoped module like '@babel/core'
        const parentParentDir = path.dirname(parentDir)
        return path.basename(parentParentDir) === 'node_modules'
    }
    return false
}

// Determines if a file path is a 1p dep in the package store.
// See js/private/test/js_run_devserver/js_run_devserver.spec.mjs for examples.
export function is1pPackageStoreDep(p) {
    // unscoped1p: https://regex101.com/r/hBR08J/1
    const unscoped1p =
        /^.+\/\.aspect_rules_js\/([^@\/]+)@0\.0\.0\/node_modules\/\1$/
    // scoped1p: https://regex101.com/r/bWS7Hl/1
    const scoped1p =
        /^.+\/\.aspect_rules_js\/@([^@+\/]+)\+([^@+\/]+)@0\.0\.0\/node_modules\/@\1\/\2$/
    return p.match(unscoped1p) || p.match(scoped1p)
}

// Hashes a file using a read stream. Based on https://github.com/kodie/md5-file.
async function generateChecksum(p) {
    return new Promise((resolve, reject) => {
        const output = crypto.createHash('md5')
        const input = fs.createReadStream(p)
        input.on('error', (err) => {
            reject(err)
        })
        output.once('readable', () => {
            resolve(output.read().toString('hex'))
        })
        input.pipe(output)
    })
}

// Converts a size in bytes to a human readable friendly number such as "24 KiB"
export function friendlyFileSize(bytes) {
    if (!bytes) {
        return '0 B'
    }
    const e = Math.floor(Math.log(bytes) / Math.log(1024))
    if (e == 0) {
        return `${bytes} B`
    }
    return (
        (bytes / Math.pow(1024, Math.min(e, 5))).toFixed(1) +
        ' ' +
        ' KMGTP'.charAt(Math.min(e, 5)) +
        'iB'
    )
}

// https://stackoverflow.com/a/42299191
function partitionArray(array, callback) {
    return array.reduce(
        function (result, element, i) {
            callback(element, i, array)
                ? result[0].push(element)
                : result[1].push(element)

            return result
        },
        [[], []]
    )
}

// Recursively copies a file, symlink or directory to a destination. If the file has been previously
// synced it is only re-copied if the file's last modified time has changed since the last time that
// file was copied. Symlinks are not copied but instead a symlink is created under the destination
// pointing to the source symlink.
async function syncRecursive(src, dst, sandbox, writePerm) {
    try {
        const lstat = await fs.promises.lstat(src)
        const last = syncedTime.get(src)
        if (!lstat.isDirectory() && last && lstat.mtimeMs == last) {
            // this file is already up-to-date
            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Skipping file ${src.slice(
                        RUNFILES_ROOT.length + 1
                    )} since its timestamp has not changed`
                )
            }
            return 0
        }
        const exists = syncedTime.has(src) || fs.existsSync(dst)
        syncedTime.set(src, lstat.mtimeMs)
        if (lstat.isSymbolicLink()) {
            const srcWorkspacePath = src.slice(RUNFILES_ROOT.length + 1)
            let symlinkMeta = ''
            if (isNodeModulePath(src)) {
                let linkPath = await fs.promises.readlink(src)
                if (path.isAbsolute(linkPath)) {
                    linkPath = path.relative(src, linkPath)
                }
                // Special case for 1p node_modules symlinks
                const maybe1pSync = path.normalize(
                    path.join(sandbox, srcWorkspacePath, linkPath)
                )
                if (fs.existsSync(maybe1pSync)) {
                    src = maybe1pSync
                    symlinkMeta = '1p'
                }
                if (!symlinkMeta) {
                    // Special case for node_modules symlinks where we should _not_ symlink to the runfiles but rather
                    // the bin copy of the symlink to avoid finding npm packages in multiple node_modules trees
                    const maybeBinSrc = path.join(
                        process.env.JS_BINARY__EXECROOT,
                        process.env.JS_BINARY__BINDIR,
                        srcWorkspacePath
                    )
                    if (fs.existsSync(maybeBinSrc)) {
                        src = maybeBinSrc
                        symlinkMeta = 'bazel-out'
                    }
                }
            }
            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Syncing symlink ${srcWorkspacePath}${
                        symlinkMeta ? ` (${symlinkMeta})` : ''
                    }`
                )
            }
            if (exists) {
                await fs.promises.unlink(dst)
            } else {
                // Intentionally synchronous; see comment on mkdirpSync
                mkdirpSync(path.dirname(dst))
            }
            await fs.promises.symlink(src, dst)
            return 1
        } else if (lstat.isDirectory()) {
            const contents = await fs.promises.readdir(src)
            if (!exists) {
                // Intentionally synchronous; see comment on mkdirpSync
                mkdirpSync(dst)
            }
            return (
                await Promise.all(
                    contents.map(
                        async (entry) =>
                            await syncRecursive(
                                path.join(src, entry),
                                path.join(dst, entry),
                                sandbox,
                                writePerm
                            )
                    )
                )
            ).reduce((s, t) => s + t, 0)
        } else {
            const lastChecksum = syncedChecksum.get(src)
            const checksum = await generateChecksum(src)
            if (lastChecksum && checksum == lastChecksum) {
                // the file contents have not changed since the last sync
                if (process.env.JS_BINARY__LOG_DEBUG) {
                    console.error(
                        `Skipping file ${src.slice(
                            RUNFILES_ROOT.length + 1
                        )} since contents have not changed`
                    )
                }
                return 0
            }
            syncedChecksum.set(src, checksum)

            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Syncing file ${src.slice(
                        RUNFILES_ROOT.length + 1
                    )} (${friendlyFileSize(lstat.size)})`
                )
            }
            if (exists) {
                await fs.promises.unlink(dst)
            } else {
                // Intentionally synchronous; see comment on mkdirpSync
                mkdirpSync(path.dirname(dst))
            }

            await fs.promises.copyFile(src, dst)
            if (writePerm) {
                const s = await fs.promises.stat(dst)
                const mode = s.mode | fs.constants.S_IWUSR
                if (process.env.JS_BINARY__LOG_DEBUG) {
                    console.error(
                        `Adding write permissions to file ${src.slice(
                            RUNFILES_ROOT.length + 1
                        )}: ${(mode & parseInt('777', 8)).toString(8)}`
                    )
                }
                await fs.promises.chmod(dst, mode)
            }
            return 1
        }
    } catch (e) {
        console.error(e)
        process.exit(1)
    }
}

// Delete files from sandbox
async function deleteFiles(previousFiles, updatedFiles, sandbox) {
    const startTime = perf_hooks.performance.now()

    let totalDeleted = 0

    // Remove files that were previously synced but are no longer in the updated list of files to sync
    const updatedFilesSet = new Set(updatedFiles)
    for (const f of previousFiles) {
        if (updatedFilesSet.has(f)) {
            continue
        }

        console.error(`Deleting ${f}`)

        // clear any matching files or files rooted at this folder from the
        // syncedTime and syncedChecksum maps
        const srcPath = path.join(RUNFILES_ROOT, f)
        for (const k of syncedTime.keys()) {
            if (k == srcPath || k.startsWith(srcPath + '/')) {
                syncedTime.delete(k)
            }
        }
        for (const k of syncedChecksum.keys()) {
            if (k == srcPath || k.startsWith(srcPath + '/')) {
                syncedChecksum.delete(k)
            }
        }

        // clear mkdirs if we have deleted any files so we re-populate on next sync
        mkdirs.clear()

        const rmPath = path.join(sandbox, f)
        try {
            fs.rmSync(rmPath, { recursive: true, force: true })
        } catch (e) {
            console.error(
                `An error has occurred while deleting the synced file ${rmPath}. Error: ${e}`
            )
        }
        totalDeleted++
    }

    var endTime = perf_hooks.performance.now()

    if (totalDeleted > 0) {
        console.error(
            `${totalDeleted} file${totalDeleted > 1 ? 's' : ''}/folder${
                totalDeleted > 1 ? 's' : ''
            } deleted in ${Math.round(endTime - startTime)} ms`
        )
    }
}

// Sync list of files to the sandbox
async function syncFiles(files, sandbox, writePerm) {
    console.error(`+ Syncing ${files.length} files && folders...`)
    const startTime = perf_hooks.performance.now()

    const [nodeModulesFiles, otherFiles] = partitionArray(
        files,
        isNodeModulePath
    )

    const [packageStore1pDeps, otherNodeModulesFiles] = partitionArray(
        nodeModulesFiles,
        is1pPackageStoreDep
    )

    // Sync non-node_modules files first since syncing 1p js_library linked node_modules symlinks
    // requires the files they point to be in place.
    if (otherFiles.length > 0 && process.env.JS_BINARY__LOG_DEBUG) {
        console.error(
            `+ Syncing ${otherFiles.length} non-node_modules files & folders...`
        )
    }

    let totalSynced = (
        await Promise.all(
            otherFiles.map(async (file) => {
                const src = path.join(RUNFILES_ROOT, file)
                const dst = path.join(sandbox, file)
                return await syncRecursive(src, dst, sandbox, writePerm)
            })
        )
    ).reduce((s, t) => s + t, 0)

    // Sync first-party package store files before other node_modules files since correctly syncing
    // direct 1p node_modules symlinks depends on checking if the package store synced files exist.
    if (packageStore1pDeps.length > 0 && process.env.JS_BINARY__LOG_DEBUG) {
        console.error(
            `+ Syncing ${packageStore1pDeps.length} first party package store dep(s)`
        )
    }

    totalSynced += (
        await Promise.all(
            packageStore1pDeps.map(async (file) => {
                const src = path.join(RUNFILES_ROOT, file)
                const dst = path.join(sandbox, file)
                return await syncRecursive(src, dst, sandbox, writePerm)
            })
        )
    ).reduce((s, t) => s + t, 0)

    // Finally sync all remaining node_modules files
    if (otherNodeModulesFiles.length > 0 && process.env.JS_BINARY__LOG_DEBUG) {
        console.error(
            `+ Syncing ${otherNodeModulesFiles.length} other node_modules files`
        )
    }

    totalSynced += (
        await Promise.all(
            otherNodeModulesFiles.map(async (file) => {
                const src = path.join(RUNFILES_ROOT, file)
                const dst = path.join(sandbox, file)
                return await syncRecursive(src, dst, sandbox, writePerm)
            })
        )
    ).reduce((s, t) => s + t, 0)

    var endTime = perf_hooks.performance.now()
    console.error(
        `${totalSynced} file${
            totalSynced > 1 ? 's' : ''
        } synced in ${Math.round(endTime - startTime)} ms`
    )
}

async function main(args, sandbox) {
    console.error(
        `\n\nStarting js_run_devserver ${process.env.JS_BINARY__TARGET}`
    )

    const configPath = path.join(RUNFILES_ROOT, args[0])

    const config = JSON.parse(await fs.promises.readFile(configPath))

    await syncFiles(
        config.data_files,
        sandbox,
        config.grant_sandbox_write_permissions
    )

    return new Promise((resolve) => {
        const cwd = process.env.JS_BINARY__CHDIR
            ? path.join(sandbox, process.env.JS_BINARY__CHDIR)
            : sandbox

        const tool = config.tool
            ? path.join(RUNFILES_ROOT, config.tool)
            : config.command

        const toolArgs = args.slice(1)

        console.error(`Running '${tool} ${toolArgs.join(' ')}' in ${cwd}\n\n`)

        const env = {
            ...process.env,
            BAZEL_BINDIR: '.', // no load bearing but it may be depended on by users
            JS_BINARY__CHDIR: '',
            JS_BINARY__NO_CD_BINDIR: '1',
        }

        if (config.use_execroot_entry_point) {
            // Configure a potential js_binary tool to use the execroot entry_point.
            // js_run_devserver is a special case where we need to set the BAZEL_BINDIR
            // to determine the execroot entry point but since the tool is running
            // in a custom sandbox we don't want to cd into the BAZEL_BINDIR in the launcher
            // (JS_BINARY__NO_CD_BINDIR is set above)
            env['JS_BINARY__USE_EXECROOT_ENTRY_POINT'] = '1'
            env['BAZEL_BINDIR'] = config.bazel_bindir
            if (config.allow_execroot_entry_point_with_no_copy_data_to_bin) {
                env[
                    'JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN'
                ] = '1'
            }
        }

        const proc = child_process.spawn(tool, toolArgs, {
            cwd: cwd,
            env: env,

            // Pipe stdin data to the child process rather than simply letting
            // the child process inherit the stream and consume the data itself.
            // If the child process consumes the data itself, then ibazel's
            // messages like "IBAZEL_BUILD_COMPLETED SUCCESS" won't be seen by
            // this 'js_run_devserver' process. Furthermore, we want to sync the
            // files to the js_run_devserver's custom sandbox before alerting
            // the child process of a successful build to allow it to read the
            // latest files. This solves: https://github.com/aspect-build/rules_js/issues/1242
            stdio: ['pipe', 'inherit', 'inherit'],
        })

        proc.on('close', (code) => {
            console.error(`child tool process exited with code ${code}`)
            resolve()
            process.exit(code)
        })

        // Process stdin data in order using a promise chain.
        let syncing = Promise.resolve()
        process.stdin.on('data', async (chunk) => {
            return (syncing = syncing.then(() => processChunk(chunk)))
        })

        async function processChunk(chunk) {
            try {
                const chunkString = chunk.toString()
                if (chunkString.includes('IBAZEL_BUILD_COMPLETED SUCCESS')) {
                    if (process.env.JS_BINARY__LOG_DEBUG) {
                        console.error('IBAZEL_BUILD_COMPLETED SUCCESS')
                    }

                    const oldFiles = config.data_files

                    // Re-parse the config file to get the latest list of data files to copy
                    const updatedDataFiles = JSON.parse(
                        await fs.promises.readFile(configPath)
                    ).data_files

                    // Await promises to catch any exceptions, and wait for the
                    // sync to be complete before writing to stdin of the child
                    // process
                    await Promise.all([
                        // Remove files that were previously synced but are no longer in the updated list of files to sync
                        deleteFiles(oldFiles, updatedDataFiles, sandbox),

                        // Sync changed files
                        syncFiles(
                            updatedDataFiles,
                            sandbox,
                            config.grant_sandbox_write_permissions
                        ),
                    ])

                    // The latest state of copied data files
                    config.data_files = updatedDataFiles
                } else if (chunkString.includes('IBAZEL_BUILD_STARTED')) {
                    if (process.env.JS_BINARY__LOG_DEBUG) {
                        console.error('IBAZEL_BUILD_STARTED')
                    }
                }

                // Forward stdin to the subprocess. See comment about
                // https://github.com/aspect-build/rules_js/issues/1242 where
                // `proc` is spawned
                await new Promise((resolve) => {
                    // note: ignoring error - if this write to stdin fails,
                    // it's probably okay. Can add error handling later if needed
                    proc.stdin.write(chunk, resolve)
                })
            } catch (e) {
                console.error(
                    `An error has occurred while incrementally syncing files. Error: ${e}`
                )
                process.exit(1)
            }
        }
    })
}

;(async () => {
    if (process.env.__RULES_JS_UNIT_TEST__)
        // short-circuit for unit tests
        return
    let sandbox
    try {
        sandbox = path.join(
            await fs.promises.mkdtemp(
                path.join(os.tmpdir(), 'js_run_devserver-')
            ),
            process.env.JS_BINARY__WORKSPACE
        )
        // Intentionally synchronous; see comment on mkdirpSync
        mkdirpSync(path.join(sandbox, process.env.JS_BINARY__CHDIR || ''))
        await main(process.argv.slice(2), sandbox)
    } catch (e) {
        console.error(e)
        process.exit(1)
    } finally {
        try {
            if (sandbox) {
                await fs.promises.rm(sandbox, { recursive: true })
            }
        } catch (e) {
            console.error(
                `An error has occurred while removing the sandbox folder at ${sandbox}. Error: ${e}`
            )
        }
    }
})()
