import * as path from 'node:path'
import * as perf_hooks from 'node:perf_hooks'
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as child_process from 'node:child_process'
import * as crypto from 'node:crypto'
import * as readline from 'node:readline'

import {
    AspectWatchProtocol,
    MessageType,
} from '../../watch/aspect_watch_protocol.mjs'

// Environment constants
const {
    JS_BINARY__EXECROOT,
    JS_BINARY__BINDIR,
    JS_BINARY__WORKSPACE,
    JS_BINARY__RUNFILES,
    JS_BINARY__LOG_DEBUG,
} = process.env

const RUNFILES_ROOT = path.join(JS_BINARY__RUNFILES, JS_BINARY__WORKSPACE)

// Globals
const syncedTime = new Map()
const syncedChecksum = new Map()
const mkdirs = new Set()

// Set of all data file paths (workspace-relative, posix separators) that the sandbox is expected to
// contain after the current sync. Used to resolve node_modules symlinks to their in-sandbox targets
// without depending on the order in which entries happen to be synced.
const entryPaths = new Set()

// When true the package store is materialized inside the sandbox and node_modules symlinks are
// pointed at it instead of at the execroot. Set from the rule config in main().
let sandboxPackageStore = false

// How many levels of symlinked directories will be dereferenced into the sandbox before giving up.
// Guards against symlinked directories that point at one another, which would recurse forever.
const MAX_DEREF_DEPTH = 32

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

    fs.mkdirSync(p, { recursive: true })

    do {
        mkdirs.add(p)
    } while (!mkdirs.has((p = path.dirname(p))))
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

// Determines if a file path is within the rules_js package store.
// See js/private/test/js_run_devserver/js_run_devserver.spec.mjs for examples.
export function isPackageStorePath(p) {
    return p.includes('/.aspect_rules_js/')
}

// Determines if a file path is anywhere under a node_modules tree, including paths such as
// node_modules/.bin/next and files within the contents of a package, which isNodeModulePath does
// not match since it only matches the package directory itself.
// See js/private/test/js_run_devserver/js_run_devserver.spec.mjs for examples.
export function isUnderNodeModules(p) {
    return /(^|\/)node_modules\//.test(toPosix(p))
}

function toPosix(p) {
    return path.sep === '/' ? p : p.split(path.sep).join('/')
}

// Records the full set of data files that the current sync will place in the sandbox.
function updateEntryPaths(files) {
    entryPaths.clear()
    for (const [file] of files) {
        entryPaths.add(toPosix(file))
    }
}

// Reads a symlink in the runfiles tree and resolves it to the equivalent path inside the sandbox,
// or undefined when the target is not something this devserver syncs into the sandbox.
async function readSandboxSymlinkTarget(file, src, sandbox) {
    let linkPath = await fs.promises.readlink(src)
    const linkAbs = path.resolve(path.dirname(src), linkPath)
    linkPath = path.relative(src, linkAbs) || '.'
    return resolveSandboxSymlinkTarget(sandbox, file, linkPath, entryPaths)
}

// Resolves the target of a symlink to a path inside the sandbox, or returns undefined
// if the target is not something this devserver syncs into the sandbox. `linkPath` is the symlink
// target relative to the link itself, as computed by readSandboxSymlinkTarget.
export function resolveSandboxSymlinkTarget(sandbox, file, linkPath, entries) {
    const target = path.join(sandbox, file, linkPath)
    let rel = toPosix(path.relative(sandbox, target))
    if (!rel || rel === '..' || rel.startsWith('../')) {
        // Escapes the sandbox root; nothing we can point at.
        return undefined
    }
    // The target is in the sandbox if it, or a directory entry containing it, is synced.
    while (rel && rel !== '.') {
        if (entries.has(rel)) {
            return target
        }
        const parent = path.posix.dirname(rel)
        if (parent === rel) {
            break
        }
        rel = parent
    }
    return undefined
}

// Stats a path following symlinks, or returns null for a broken link so that the caller can
// recreate it as a symlink rather than failing the sync.
async function statFollowingLinks(src, file) {
    try {
        return await fs.promises.stat(src)
    } catch (e) {
        if (JS_BINARY__LOG_DEBUG) {
            console.error(`Could not follow symlink ${file}: ${e.message}`)
        }
        return null
    }
}

// Utility function to retry an async operation with backoff
async function withRetry(
    operation,
    description,
    maxRetries = 3,
    initialDelay = 100
) {
    let retries = maxRetries
    let delay = initialDelay
    while (retries > 0) {
        try {
            return await operation()
        } catch (e) {
            if (e.code === 'ENOENT' && retries > 1) {
                retries--
                console.error(
                    `Retrying ${description} in ${delay}ms (${retries} attempts remaining)`
                )
                await new Promise((resolve) => setTimeout(resolve, delay))
                delay += initialDelay
                continue
            }
            console.error(
                `Failed ${description} after all retries: ${e.message}`
            )
            throw e
        }
    }
}

// Hashes a file using a read stream. Based on https://github.com/kodie/md5-file.
async function generateChecksum(p) {
    return withRetry(
        () =>
            new Promise((resolve, reject) => {
                const output = crypto.createHash('md5')
                const input = fs.createReadStream(p)
                input.on('error', reject)
                output.once('readable', () => {
                    resolve(output.read().toString('hex'))
                })
                input.pipe(output)
            }),
        `generateChecksum for ${p}`
    )
}

// Converts a chdir value, which names a path in the output tree, to one relative to the root of
// the custom sandbox. The sandbox mirrors the runfiles tree, where an external repository is a
// top-level directory beside the main one rather than under "external/".
export function sandboxRelativeChdir(chdir) {
    if (!chdir) {
        return ''
    }
    return chdir.startsWith('external/')
        ? '../' + chdir.slice('external/'.length)
        : chdir
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

async function syncSymlink(file, src, dst, sandbox, exists, sandboxSrc) {
    let symlinkMeta = ''
    if (sandboxSrc) {
        // The target is synced into the sandbox, so point at it rather than at the execroot. This
        // keeps realpath() of the link inside the sandbox root, which bundlers that enforce a
        // project-root boundary (e.g. Turbopack) require.
        src = sandboxSrc
        symlinkMeta = 'sandbox'
    } else if (isNodeModulePath(file)) {
        let linkPath = await fs.promises.readlink(src)
        const linkAbs = path.resolve(path.dirname(src), linkPath)
        linkPath = path.relative(src, linkAbs) || '.'
        // Special case for 1p node_modules symlinks
        const maybe1pSync = path.join(sandbox, file, linkPath)
        if (fs.existsSync(maybe1pSync)) {
            src = maybe1pSync
            symlinkMeta = '1p'
        }
        if (!symlinkMeta) {
            // Special case for node_modules symlinks where we should _not_ symlink to the runfiles but rather
            // the bin copy of the symlink to avoid finding npm packages in multiple node_modules trees
            const maybeBinSrc = path.join(
                JS_BINARY__EXECROOT,
                JS_BINARY__BINDIR,
                file
            )
            if (fs.existsSync(maybeBinSrc)) {
                src = maybeBinSrc
                symlinkMeta = 'bazel-out'
            }
        }
    }
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `Syncing symlink ${file}${symlinkMeta ? ` (${symlinkMeta})` : ''}`
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
}

async function syncDirectory(file, src, sandbox, writePerm, derefDepth = 0) {
    if (JS_BINARY__LOG_DEBUG) {
        console.error(`Syncing directory ${file}...`)
    }
    const contents = await fs.promises.readdir(src)
    return (
        await Promise.all(
            contents.map(
                async (entry) =>
                    await syncRecursive(
                        file + path.sep + entry,
                        undefined,
                        sandbox,
                        writePerm,
                        derefDepth
                    )
            )
        )
    ).reduce((s, t) => s + t, 0)
}

// Materializes src at dst using a copy-on-write clone when possible. Node falls back to a regular
// copy when the filesystem does not support cloning. Unlike a hardlink, both forms create a new
// inode, so a devserver can chmod or modify the sandbox file without mutating the Bazel output.
async function materializeFile(src, dst) {
    await fs.promises.copyFile(src, dst, fs.constants.COPYFILE_FICLONE)
}

async function syncFile(file, src, dst, exists, lstat, writePerm) {
    if (JS_BINARY__LOG_DEBUG) {
        console.error(
            `Syncing file ${file}${
                lstat ? ' (' + friendlyFileSize(lstat.size) + ')' : ''
            })`
        )
    }
    if (exists) {
        await fs.promises.unlink(dst)
    } else {
        // Intentionally synchronous; see comment on mkdirpSync
        mkdirpSync(path.dirname(dst))
    }

    await withRetry(
        () => materializeFile(src, dst),
        `copyFile from ${src} to ${dst}`
    )

    if (writePerm) {
        const s = await fs.promises.stat(dst)
        const mode = s.mode | fs.constants.S_IWUSR
        if (JS_BINARY__LOG_DEBUG) {
            console.error(
                `Adding write permissions to file ${file}: ${(
                    mode & parseInt('777', 8)
                ).toString(8)}`
            )
        }
        await fs.promises.chmod(dst, mode)
    }
    return 1
}

// Recursively copies a file, symlink or directory to a destination. If the file has been previously
// synced it is only re-copied if the file's last modified time has changed since the last time that
// file was copied. Symlinks are not copied but instead a symlink is created under the destination
// pointing to the source symlink; the exception is sandbox package store mode, where a node_modules
// symlink that would point out of the sandbox is dereferenced and its contents materialized.
async function syncRecursive(file, _, sandbox, writePerm, derefDepth = 0) {
    const src = RUNFILES_ROOT + path.sep + file
    const dst = sandbox + path.sep + file

    try {
        const lstat = await withRetry(
            () => fs.promises.lstat(src),
            `lstat for ${src}`
        )

        // Runfiles entries for npm packages are symlinks pointing at the package store in the
        // execroot. Recreating them as symlinks would put the package contents outside the sandbox
        // root, so in sandbox package store mode a node_modules symlink whose target is not itself
        // synced into the sandbox is dereferenced and its contents materialized instead.
        let sandboxSrc
        let deref = false
        let followed = null
        if (
            sandboxPackageStore &&
            lstat.isSymbolicLink() &&
            isUnderNodeModules(file)
        ) {
            sandboxSrc = await readSandboxSymlinkTarget(file, src, sandbox)
            deref = !sandboxSrc
            if (deref) {
                followed = await statFollowingLinks(src, file)
                // A broken link has nothing to dereference; recreate it as a symlink.
                deref = !!followed
            }
        }

        // A dereferenced directory is re-walked on every sync; the files within it do their own
        // up-to-date checks. The symlink's own mtime says nothing about its contents.
        const derefDirectory = deref && followed.isDirectory()

        if (derefDirectory && derefDepth >= MAX_DEREF_DEPTH) {
            // Symlinked directories that point at each other would otherwise recurse forever.
            console.error(
                `Not dereferencing ${file}: more than ${MAX_DEREF_DEPTH} levels of symlinked directories`
            )
            const exists = syncedTime.has(file) || fs.existsSync(dst)
            return syncSymlink(file, src, dst, sandbox, exists)
        }

        const last = syncedTime.get(file)
        if (
            !lstat.isDirectory() &&
            !derefDirectory &&
            last &&
            lstat.mtimeMs == last
        ) {
            // this file is already up-to-date
            if (JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Skipping file ${file} since its timestamp has not changed`
                )
            }
            return 0
        }
        const exists = syncedTime.has(file) || fs.existsSync(dst)
        syncedTime.set(file, lstat.mtimeMs)
        if (derefDirectory) {
            if (JS_BINARY__LOG_DEBUG) {
                console.error(`Dereferencing symlinked directory ${file}`)
            }
            return syncDirectory(file, src, sandbox, writePerm, derefDepth + 1)
        } else if (lstat.isSymbolicLink() && !deref) {
            return syncSymlink(file, src, dst, sandbox, exists, sandboxSrc)
        } else if (lstat.isDirectory()) {
            return syncDirectory(file, src, sandbox, writePerm, derefDepth)
        } else {
            if (sandboxPackageStore && isPackageStorePath(file)) {
                // Package store files are immutable Bazel outputs, so the mtime check above is
                // sufficient. Skip hashing them; there can be a very large number of them.
                return syncFile(file, src, dst, exists, lstat, writePerm)
            }
            const lastChecksum = syncedChecksum.get(file)
            const checksum = await generateChecksum(src)
            if (lastChecksum && checksum == lastChecksum) {
                // the file contents have not changed since the last sync
                if (JS_BINARY__LOG_DEBUG) {
                    console.error(
                        `Skipping file ${file} since contents have not changed`
                    )
                }
                return 0
            }
            syncedChecksum.set(file, checksum)

            return syncFile(file, src, dst, exists, lstat, writePerm)
        }
    } catch (e) {
        console.error(e)
        console.trace()
        process.exit(1)
    }
}

// Delete files from sandbox
async function deleteFiles(previousFiles, updatedFiles, sandbox) {
    const startTime = perf_hooks.performance.now()

    const deletions = []

    // Remove files that were previously synced but are no longer in the updated list of files to sync
    const updatedFilesSet = new Set()
    for (const [f] of updatedFiles) {
        updatedFilesSet.add(f)
    }
    for (const [f] of previousFiles) {
        if (updatedFilesSet.has(f)) {
            continue
        }

        console.error(`Deleting ${f}`)

        // clear any matching files or files rooted at this folder from the
        // syncedTime and syncedChecksum maps
        const fSlash = f + '/'
        for (const k of syncedTime.keys()) {
            if (k == f || k.startsWith(fSlash)) {
                syncedTime.delete(k)
            }
        }
        for (const k of syncedChecksum.keys()) {
            if (k == f || k.startsWith(fSlash)) {
                syncedChecksum.delete(k)
            }
        }

        // clear mkdirs if we have deleted any files so we re-populate on next sync
        mkdirs.clear()

        const rmPath = path.join(sandbox, f)
        deletions.push(
            fs.promises
                .rm(rmPath, { recursive: true, force: true })
                .catch((e) =>
                    console.error(
                        `An error has occurred while deleting the synced file ${rmPath}. Error: ${e}`
                    )
                )
        )
    }

    await Promise.all(deletions)

    var endTime = perf_hooks.performance.now()

    const totalDeleted = deletions.length
    if (totalDeleted > 0) {
        console.error(
            `${totalDeleted} file${totalDeleted > 1 ? 's' : ''}/folder${
                totalDeleted > 1 ? 's' : ''
            } deleted in ${Math.round(endTime - startTime)} ms`
        )
    }
}

// Sync list of files to the sandbox
async function syncFiles(files, sandbox, writePerm, doSync) {
    console.error(`+ Syncing ${files.length} files & folders...`)
    const startTime = perf_hooks.performance.now()

    // Partition files into node_modules and non-node_modules files
    const packageStoreDeps = []
    const otherNodeModulesFiles = []
    const otherFiles = []
    for (const fileInfo of files) {
        const file = fileInfo[0]
        if (isPackageStorePath(file)) {
            // Package store deps must land before the direct node_modules symlinks that point at
            // them. The entries list is filtered by the rule according to package_store_mode.
            packageStoreDeps.push(fileInfo)
        } else if (isNodeModulePath(file)) {
            otherNodeModulesFiles.push(fileInfo)
        } else {
            otherFiles.push(fileInfo)
        }
    }

    // Sync non-node_modules files first since syncing 1p js_library linked node_modules symlinks
    // requires the files they point to be in place.
    if (JS_BINARY__LOG_DEBUG && otherFiles.length > 0) {
        console.error(
            `+ Syncing ${otherFiles.length} non-node_modules files & folders...`
        )
    }

    let totalSynced = (
        await Promise.all(
            otherFiles.map(async ([file, isDirectory]) => {
                return await doSync(file, isDirectory, sandbox, writePerm)
            })
        )
    ).reduce((s, t) => s + t, 0)

    // Sync package store files before other node_modules files since correctly syncing direct
    // node_modules symlinks depends on the package store files they point at being in place.
    if (JS_BINARY__LOG_DEBUG && packageStoreDeps.length > 0) {
        console.error(
            `+ Syncing ${packageStoreDeps.length} package store dep(s)`
        )
    }

    totalSynced += (
        await Promise.all(
            packageStoreDeps.map(async ([file, isDirectory]) => {
                return await doSync(file, isDirectory, sandbox, writePerm)
            })
        )
    ).reduce((s, t) => s + t, 0)

    // Finally sync all remaining node_modules files
    if (JS_BINARY__LOG_DEBUG && otherNodeModulesFiles.length > 0) {
        console.error(
            `+ Syncing ${otherNodeModulesFiles.length} other node_modules files`
        )
    }

    totalSynced += (
        await Promise.all(
            otherNodeModulesFiles.map(async ([file, isDirectory]) => {
                return await doSync(file, isDirectory, sandbox, writePerm)
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

function isWindowsScript(tool) {
    const toolExtension = path.extname(tool)
    const isScriptFile = toolExtension === '.bat' || toolExtension === '.cmd'
    return isScriptFile && os.platform() === 'win32'
}

async function main(args, sandbox, config) {
    console.error(
        `\n\nStarting js_run_devserver ${process.env.JS_BINARY__TARGET}`
    )

    const entriesPath = path.join(RUNFILES_ROOT, args[1])

    sandboxPackageStore = config.package_store_mode === 'sandbox'

    const cwd = path.join(sandbox, sandboxRelativeChdir(config.chdir))

    const tool = config.tool
        ? path.join(RUNFILES_ROOT, config.tool)
        : config.command

    const toolArgs = args.slice(2)

    console.error(`Running '${tool} ${toolArgs.join(' ')}' in ${cwd}\n\n`)

    const env = {
        ...process.env,
        BAZEL_BINDIR: '.', // no load bearing but it may be depended on by users
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

    let exitCode
    if (process.env.ABAZEL_WATCH_SOCKET_FILE) {
        exitCode = await runWatchProtocol(
            config,
            entriesPath,
            sandbox,
            cwd,
            tool,
            toolArgs,
            env
        )
    } else {
        exitCode = await runIBazelProtocol(
            config,
            entriesPath,
            sandbox,
            cwd,
            tool,
            toolArgs,
            env
        )
    }

    console.error(`child tool process exited with code ${exitCode}`)
    process.exit(exitCode)
}

async function runIBazelProtocol(
    config,
    entriesPath,
    sandbox,
    cwd,
    tool,
    toolArgs,
    env
) {
    const initialFiles = await fs.promises
        .readFile(entriesPath)
        .then(JSON.parse)
    updateEntryPaths(initialFiles)

    await syncFiles(
        initialFiles,
        sandbox,
        config.grant_sandbox_write_permissions,
        syncRecursive
    )

    return new Promise((resolve) => {
        const proc = child_process.spawn(tool, toolArgs, {
            cwd: cwd,
            env: env,

            // `.cmd` and `.bat` are always executed in a shell on windows
            // and require the flag to be set per CVE-2024-27980
            shell: isWindowsScript(tool),

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

        proc.on('close', resolve)

        // Process stdin data in order using a promise chain.
        let syncing = Promise.resolve()
        const rl = readline.createInterface({ input: process.stdin })
        rl.on('line', (line) => {
            syncing = syncing.then(() => processChunk(line))
        })

        async function processChunk(chunk) {
            try {
                const chunkString = chunk.toString()
                if (chunkString.includes('IBAZEL_BUILD_COMPLETED SUCCESS')) {
                    if (JS_BINARY__LOG_DEBUG) {
                        console.error('IBAZEL_BUILD_COMPLETED SUCCESS')
                    }

                    const oldFiles = config.previous_files || []

                    // Re-parse the config file to get the latest list of data files to copy
                    const updatedDataFiles = await fs.promises
                        .readFile(entriesPath)
                        .then(JSON.parse)
                    updateEntryPaths(updatedDataFiles)

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
                            config.grant_sandbox_write_permissions,
                            syncRecursive
                        ),
                    ])

                    // The latest state of copied data files
                    config.previous_files = updatedDataFiles
                } else if (chunkString.includes('IBAZEL_BUILD_STARTED')) {
                    if (JS_BINARY__LOG_DEBUG) {
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

async function runWatchProtocol(
    config,
    entriesPath,
    sandbox,
    cwd,
    tool,
    toolArgs,
    env
) {
    // Configure the watch protocol
    const w = new AspectWatchProtocol(process.env.ABAZEL_WATCH_SOCKET_FILE)
    w.onError((err) =>
        console.error(
            `js_run_devserver[WATCH]: error received from aspect watch server: `,
            err
        )
    )
    w.onCycle(watchProtocolCycle.bind(null, config, entriesPath, sandbox))

    // Connect to the watch protocol server and begin listening for cycles
    await w.connect()

    console.error(
        `js_run_devserver[WATCH]: Connected to aspect watch server at ${w.socketFile}`
    )

    await w.awaitFirstCycle()

    console.error(`js_run_devserver[WATCH]: Initialized sandbox ${sandbox}`)

    // Start the child process async *after* establishing the connection
    const procPromise = new Promise((resolve) => {
        const proc = child_process.spawn(tool, toolArgs, {
            cwd,
            env,

            // `.cmd` and `.bat` are always executed in a shell on windows
            // and require the flag to be set per CVE-2024-27980
            shell: isWindowsScript(tool),

            stdio: 'inherit',
        })
        proc.on('close', resolve)
    })

    // Run until either the child process exits or the watch protocol connection is closed.
    await Promise.any([procPromise, w.cycle()])

    // Close the watch protocol connection, return the process exit code
    try {
        await w.disconnect()
    } catch (_) {
        // Ignore errors on disconnect, the connection may have already been closed
        // by the child process or the watch protocol server.
    }
    return await procPromise
}

async function watchProtocolCycle(config, entriesPath, sandbox, cycle) {
    // Re-parse the config file to get the latest list of data files to copy
    const newFiles = await fs.promises.readFile(entriesPath).then(JSON.parse)
    updateEntryPaths(newFiles)

    const oldFiles = config.previous_files || []
    config.previous_files = newFiles

    // Re-sync everything by default
    let filesToSync = newFiles
    let toDelete = oldFiles
    let toKeep = newFiles
    let doSync = syncRecursive

    // For CYCLE message we have more informatino about what changed and can do minimal syncing.
    if (cycle.kind == MessageType.CYCLE) {
        filesToSync = newFiles.filter(([f]) =>
            cycle.sources.hasOwnProperty(`${JS_BINARY__WORKSPACE}/${f}`)
        )
        toDelete = []
        for (const l in cycle.sources) {
            if (cycle.sources[l] === null) {
                toDelete.push([
                    l.slice(JS_BINARY__WORKSPACE.length + 1),
                    /*isDirectory=*/ false,
                ])
            }
        }
        toKeep = []
        doSync = cycleSyncRecurse.bind(null, cycle)
    }

    await Promise.all([
        deleteFiles(toDelete, toKeep, sandbox),
        syncFiles(
            filesToSync,
            sandbox,
            config.grant_sandbox_write_permissions,
            doSync
        ),
    ])
}

async function cycleSyncRecurse(cycle, file, isDirectory, sandbox, writePerm) {
    const src = RUNFILES_ROOT + path.sep + file
    const dst = sandbox + path.sep + file

    // Assume it exists if it has been synced before.
    const exists = syncedTime.has(file)

    // Assume it was updated 'now()' since we know it changed
    // TODO: potentially fetch mtime from cycle.sources[src].mtime?
    syncedTime.set(file, Date.now())

    const srcRunfilesPath = JS_BINARY__WORKSPACE + path.sep + file
    const srcRunfilesInfo = cycle.sources[srcRunfilesPath]

    // The cycleSyncRecurse function should only be called for files directly from the CYCLE event.
    if (!srcRunfilesInfo) {
        throw new Error(`File ${srcRunfilesPath} is not in the cycle sources`)
    }

    if (srcRunfilesInfo.is_symlink) {
        // See the equivalent handling in syncRecursive.
        if (sandboxPackageStore && isUnderNodeModules(file)) {
            const sandboxSrc = await readSandboxSymlinkTarget(
                file,
                src,
                sandbox
            )
            if (!sandboxSrc) {
                const followed = await statFollowingLinks(src, file)
                if (followed && followed.isDirectory()) {
                    return syncDirectory(file, src, sandbox, writePerm, 1)
                }
                if (followed) {
                    return syncFile(file, src, dst, exists, followed, writePerm)
                }
            }
            return syncSymlink(file, src, dst, sandbox, exists, sandboxSrc)
        }
        return syncSymlink(file, src, dst, sandbox, exists)
    }

    if (isDirectory) {
        return syncDirectory(file, src, sandbox, writePerm)
    } else {
        return syncFile(file, src, dst, exists, null, writePerm)
    }
}

;(async () => {
    if (process.env.__RULES_JS_UNIT_TEST__)
        // short-circuit for unit tests
        return
    let sandbox

    // Callback to cleanup the sandbox if it exists, once and only once.
    onProcessEnd(() => sandbox && removeSandbox(sandbox) && (sandbox = null))

    try {
        // The sandbox lives under the OS temp dir by default. JS_RUN_DEVSERVER_SANDBOX_DIR moves it
        // elsewhere; placing it on the same filesystem as the execroot may allow package-store
        // files to use copy-on-write clones rather than full copies.
        const sandboxParent =
            process.env.JS_RUN_DEVSERVER_SANDBOX_DIR || os.tmpdir()
        // Intentionally synchronous; see comment on mkdirpSync
        mkdirpSync(sandboxParent)
        sandbox = await fs.promises.mkdtemp(
            path.join(sandboxParent, 'js_run_devserver-')
        )
        const sandboxMain = path.join(sandbox, JS_BINARY__WORKSPACE)

        // Read before the first mkdirp below, which needs config.chdir.
        const args = process.argv.slice(2)
        const config = JSON.parse(
            await fs.promises.readFile(path.join(RUNFILES_ROOT, args[0]))
        )

        // Intentionally synchronous; see comment on mkdirpSync
        mkdirpSync(path.join(sandboxMain, sandboxRelativeChdir(config.chdir)))
        await main(args, sandboxMain, config)
    } catch (e) {
        console.error(e)
        process.exit(1)
    }
})()

function removeSandbox(sandbox) {
    try {
        if (sandbox) {
            console.error(`Deleting js_run_devserver sandbox at ${sandbox}...`)

            // Must be synchronous when invoked from process exit handler
            fs.rmSync(sandbox, { force: true, recursive: true })
        }
    } catch (e) {
        console.error(
            `An error has occurred while removing the sandbox folder at ${sandbox}. Error: ${e}`
        )
        return false
    }
    return true
}

function onProcessEnd(callback) {
    // node process exit
    process.on('exit', callback)

    // ctrl+c event
    process.on('SIGINT', callback)

    // Do not invoke on uncaught exception or errors to allow inspecting the sandbox
}
