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

// Recursively copies a file, symlink or directory to a destination. If the file has been previously
// synced it is only re-copied if the file's last modified time has changed since the last time that
// file was copied. Symlinks are not copied but instead a symlink is created under the destination
// pointing to the source symlink.
async function syncRecursive(src, dst) {
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
            if (process.env.JS_BINARY__LOG_DEBUG) {
                console.error(
                    `Syncing symlink ${src.slice(RUNFILES_ROOT.length + 1)}`
                )
            }
            if (exists) {
                await fs.promises.unlink(dst)
            } else {
                mkdirpSync(path.dirname(dst))
            }
            await fs.promises.symlink(src, dst)
            return 1
        } else if (lstat.isDirectory()) {
            const contents = await fs.promises.readdir(src)
            if (!exists) {
                mkdirpSync(dst)
            }
            return (
                await Promise.all(
                    contents.map(
                        async (entry) =>
                            await syncRecursive(
                                path.join(src, entry),
                                path.join(dst, entry)
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
                mkdirpSync(path.dirname(dst))
            }
            await fs.promises.copyFile(src, dst)
            return 1
        }
    } catch (e) {
        console.error(e)
        process.exit(1)
    }
}

// Sync list of files to the sandbox
async function sync(files, sandbox) {
    console.error('Syncing...')
    const startTime = perf_hooks.performance.now()
    const totalSynced = (
        await Promise.all(
            files.map(async (file) => {
                const src = path.join(RUNFILES_ROOT, file)
                const dst = path.join(sandbox, file)
                return await syncRecursive(src, dst)
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

    await sync(config.data_files, sandbox)

    return new Promise((resolve) => {
        const cwd = process.env.JS_BINARY__CHDIR
            ? path.join(sandbox, process.env.JS_BINARY__CHDIR)
            : sandbox

        const tool = config.tool
            ? path.join(RUNFILES_ROOT, config.tool)
            : config.command

        const toolArgs = args.slice(1)

        console.error(`Running '${tool} ${toolArgs.join(' ')}' in ${cwd}\n\n`)

        const proc = child_process.spawn(tool, toolArgs, {
            cwd: cwd,
            stdio: 'inherit',
            env: {
                ...process.env,
                BAZEL_BINDIR: '.',
                JS_BINARY__CHDIR: '',
            },
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
                            sandbox
                        )
                    )
                    // Await promise to catch any exceptions
                    await syncing
                } else if (chunkString.includes('IBAZEL_BUILD_STARTED')) {
                    if (process.env.JS_BINARY__LOG_DEBUG) {
                        console.error('IBAZEL_BUILD_STARTED')
                    }
                }
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
