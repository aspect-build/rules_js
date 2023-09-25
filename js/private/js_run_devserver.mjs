import * as path from 'node:path'
import * as perf_hooks from 'node:perf_hooks'
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as child_process from 'node:child_process'

// Globals
const RUNFILES_ROOT = path.join(
    process.env.JS_BINARY__RUNFILES,
    process.env.JS_BINARY__WORKSPACE
)
const synced = new Map()
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
//
// Examples:
//     isNodeModulePath('/private/var/.../node_modules/@babel/core')  // true
//     isNodeModulePath('/private/var/.../node_modules/lodash')       // true
//     isNodeModulePath('/private/var/.../some-file.js')              // false
function isNodeModulePath(srcPath) {
    const parentDir = path.dirname(srcPath);
    const parentDirName = path.basename(parentDir);

    if (parentDirName === 'node_modules') {
        // unscoped module like 'lodash'
        return true;
    } else if (parentDirName.startsWith('@')) {
        // scoped module like '@babel/core'
        const parentParentDir = path.dirname(parentDir);
        return path.basename(parentParentDir) === 'node_modules';
    }
    return false;
}

// Recursively copies a file, symlink or directory to a destination. If the file has been previously
// synced it is only re-copied if the file's last modified time has changed since the last time that
// file was copied. Symlinks are not copied but instead a symlink is created under the destination
// pointing to the source symlink.
async function syncRecursive(src, dst, writePerm) {
    try {
        const lstat = await fs.promises.lstat(src)
        const last = synced.get(src)
        if (!lstat.isDirectory() && last && lstat.mtimeMs == last) {
            // this file is already up-to-date
            return 0
        }
        const exists = synced.has(src) || fs.existsSync(dst)
        synced.set(src, lstat.mtimeMs)
        if (lstat.isSymbolicLink()) {
            const srcWorkspacePath = src.slice(RUNFILES_ROOT.length + 1)
            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(`Syncing symlink ${srcWorkspacePath}`)
            }
            if (isNodeModulePath(src)) {
                // Special case for node_modules symlinks where we should _not_ symlink to the runfiles but rather
                // the bin copy of the symlink to avoid finding npm packages in multiple node_modules trees
                const maybeBinSrc = path.join(
                    process.env.JS_BINARY__EXECROOT,
                    process.env.JS_BINARY__BINDIR,
                    srcWorkspacePath
                )
                if (fs.existsSync(maybeBinSrc)) {
                    if (process.env.JS_BINARY__LOG_DEBUG) {
                        console.error(
                            `Syncing to bazel-out copy of symlink ${srcWorkspacePath}`
                        )
                    }
                    src = maybeBinSrc
                }
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
                                writePerm
                            )
                    )
                )
            ).reduce((s, t) => s + t, 0)
        } else {
            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Syncing file ${src.slice(RUNFILES_ROOT.length + 1)}`
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
                console.error(
                    `Adding write permissions to file ${src.slice(
                        RUNFILES_ROOT.length + 1
                    )}: ${(mode & parseInt('777', 8)).toString(8)}`
                )
                await fs.promises.chmod(dst, mode)
            }
            return 1
        }
    } catch (e) {
        console.error(e)
        process.exit(1)
    }
}

// Sync list of files to the sandbox
async function sync(files, sandbox, writePerm) {
    console.error('Syncing...')
    const startTime = perf_hooks.performance.now()
    const totalSynced = (
        await Promise.all(
            files.map(async (file) => {
                const src = path.join(RUNFILES_ROOT, file)
                const dst = path.join(sandbox, file)
                return await syncRecursive(src, dst, writePerm)
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

    await sync(
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

        let syncing = Promise.resolve()
        process.stdin.on('data', async (chunk) => {
            try {
                const chunkString = chunk.toString()
                if (chunkString.includes('IBAZEL_BUILD_COMPLETED SUCCESS')) {
                    if (process.env.JS_BINARY__LOG_DEBUG) {
                        console.error('IBAZEL_BUILD_COMPLETED SUCCESS')
                    }
                    // Chain promises via syncing.then()
                    syncing = syncing.then(() =>
                        sync(
                            // Re-parse the config file to get the latest list of data files to copy
                            JSON.parse(fs.readFileSync(configPath)).data_files,
                            sandbox,
                            config.grant_sandbox_write_permissions
                        )
                    )
                    // Await promise to catch any exceptions, and wait for the
                    // sync to be complete before writing to stdin of the child
                    // process
                    await syncing
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
        })
    })
}

;(async () => {
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
