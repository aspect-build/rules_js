// Exercises re-syncs of the js_run_devserver sandbox, as ibazel and the watch protocol perform them,
// against a synthetic runfiles tree as the node fs patches present it: package store entries are
// directories and node_modules links between packages are relative symlinks.
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'

const base = fs.mkdtempSync(path.join(os.tmpdir(), 'devserver-sync-'))
const runfiles = path.join(base, 'runfiles')
const STORE = 'node_modules/.aspect_rules_js/pkg@1.0.0/node_modules/pkg'
const LINK = 'app/node_modules/pkg'
const STORE_ENTRY = [STORE, 1]
const LINK_ENTRY = [LINK, 0]

function write(p) {
    fs.mkdirSync(path.dirname(p), { recursive: true })
    fs.writeFileSync(p, p)
}

function symlink(target, p) {
    fs.mkdirSync(path.dirname(p), { recursive: true })
    fs.symlinkSync(target, p)
}

const main = path.join(runfiles, '_main')
write(path.join(main, STORE, 'a.js'))
symlink(
    path.relative(path.join(main, path.dirname(LINK)), path.join(main, STORE)),
    path.join(main, LINK)
)

// The module reads these when it is loaded
Object.assign(process.env, {
    JS_BINARY__RUNFILES: runfiles,
    JS_BINARY__WORKSPACE: '_main',
    JS_BINARY__EXECROOT: base,
    JS_BINARY__BINDIR: 'bazel-out',
})

function check(description, actual, expected) {
    if (actual !== expected) {
        console.error(
            `ERROR: ${description}: expected '${expected}' but got '${actual}'`
        )
        process.exit(1)
    }
}

// Each scenario gets its own instance of the module, since it keeps what it has synced into a
// sandbox in module state, and its own sandbox.
async function newDevserver(scenario) {
    const devserver = await import(
        `../../devserver/js_run_devserver.mjs?${scenario}`
    )
    devserver.applyConfig({ package_store_mode: 'sandbox' }, '1')
    const sandbox = path.join(
        fs.mkdtempSync(path.join(base, 'js_run_devserver-')),
        '_main'
    )
    return { devserver, sandbox }
}

// Sandbox package store mode requires the node fs patches
{
    const devserver = await import('../../devserver/js_run_devserver.mjs?nopatch')
    let error = null
    try {
        devserver.applyConfig({ package_store_mode: 'sandbox' }, '0')
    } catch (e) {
        error = e
    }
    check('applyConfig without fs patches throws', !!error, true)
    devserver.applyConfig({ package_store_mode: 'execroot' }, '0')
}

// A node_modules link points at its target in the sandbox when that target is synced, and back out
// of the sandbox when it is not. The link itself does not change in runfiles when the entries do, so
// it has to be re-evaluated regardless.
for (const protocol of ['ibazel', 'watch']) {
    const { devserver, sandbox } = await newDevserver(protocol)
    const link = path.join(sandbox, LINK)
    const inSandbox = () =>
        fs.lstatSync(link).isSymbolicLink() &&
        fs.readlinkSync(link) === path.join(sandbox, STORE)
    const withEntry = [STORE_ENTRY, LINK_ENTRY]
    const withoutEntry = [LINK_ENTRY]

    // Syncs a changed list of entries the way each protocol does. `storeSource` is what the watch
    // protocol reports for the store entry, the only path that changed: null once it is deleted.
    const entriesPath = path.join(base, `${protocol}-entries.json`)
    const config = {}
    let previous = []
    const resync = async (files, storeSource) => {
        if (protocol === 'ibazel') {
            devserver.updateEntryPaths(files)
            await Promise.all([
                devserver.deleteFiles(previous, files, sandbox),
                devserver.syncFiles(
                    files,
                    sandbox,
                    false,
                    devserver.syncRecursive
                ),
            ])
            previous = files
        } else {
            fs.writeFileSync(entriesPath, JSON.stringify(files))
            const cycle =
                storeSource === undefined
                    ? { kind: 'CYCLE_RESET', sources: {} }
                    : {
                          kind: 'CYCLE',
                          sources: { [`_main/${STORE}`]: storeSource },
                      }
            await devserver.watchProtocolCycle(
                config,
                entriesPath,
                sandbox,
                cycle
            )
        }
    }

    await resync(withEntry)
    check(`${protocol}: link to a synced entry`, inSandbox(), true)
    check(
        `${protocol}: package copied`,
        fs.readFileSync(path.join(link, 'a.js'), 'utf8'),
        path.join(main, STORE, 'a.js')
    )

    await resync(withoutEntry, null)
    check(`${protocol}: entry no longer synced`, inSandbox(), false)
    check(
        `${protocol}: package removed`,
        fs.existsSync(path.join(sandbox, STORE)),
        false
    )

    await resync(withEntry, { is_symlink: true })
    check(`${protocol}: entry synced again`, inSandbox(), true)

    // An unchanged link is left alone rather than recreated
    const before = fs.lstatSync(link, { bigint: true }).ino
    await resync(withEntry, { is_symlink: true })
    check(
        `${protocol}: unchanged link kept`,
        fs.lstatSync(link, { bigint: true }).ino,
        before
    )
}

fs.rmSync(base, { recursive: true, force: true })
