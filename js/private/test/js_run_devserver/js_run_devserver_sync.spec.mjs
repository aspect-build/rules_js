// Exercises re-syncs of the js_run_devserver sandbox, as ibazel and the watch protocol perform them,
// against a synthetic runfiles tree whose package store can be changed between syncs.
import * as fs from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'

const base = fs.mkdtempSync(path.join(os.tmpdir(), 'devserver-sync-'))
// Stands in for a package in the package store in bazel-out, which runfiles link to absolutely
const pkgOut = path.join(base, 'bazel-out', 'pkg')
const runfiles = path.join(base, 'runfiles')
const STORE = 'node_modules/.aspect_rules_js/pkg@1.0.0/node_modules/pkg'
const LINK = 'app/node_modules/pkg'
const STORE_ENTRY = [STORE, 1]
const LINK_ENTRY = [LINK, 0]

function write(p) {
    fs.mkdirSync(path.dirname(p), { recursive: true })
    fs.writeFileSync(p, p)
}

function resetPackage(files) {
    fs.rmSync(pkgOut, { recursive: true, force: true })
    for (const f of files) {
        write(path.join(pkgOut, f))
    }
}

function symlink(target, p) {
    fs.mkdirSync(path.dirname(p), { recursive: true })
    fs.symlinkSync(target, p)
}

const main = path.join(runfiles, '_main')
symlink(pkgOut, path.join(main, STORE))
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

// Each scenario gets its own instance of the module, since it keeps what it has synced into a
// sandbox in module state, and its own sandbox.
async function newDevserver(scenario) {
    const devserver = await import(
        `../../devserver/js_run_devserver.mjs?${scenario}`
    )
    devserver.applyConfig({ package_store_mode: 'sandbox' })
    const sandbox = path.join(
        fs.mkdtempSync(path.join(base, 'js_run_devserver-')),
        '_main'
    )
    const sync = async (files) => {
        devserver.updateEntryPaths(files)
        await devserver.syncFiles(
            files,
            sandbox,
            false,
            devserver.syncRecursive
        )
    }
    return { devserver, sandbox, sync }
}

// Lists the files under a directory, relative to it
function list(dir) {
    const files = []
    const walk = (d, prefix) => {
        for (const e of fs.readdirSync(d, { withFileTypes: true })) {
            if (e.isDirectory()) {
                walk(path.join(d, e.name), prefix + e.name + '/')
            } else {
                files.push(prefix + e.name)
            }
        }
    }
    walk(dir, '')
    return files.sort().join(' ')
}

function check(description, actual, expected) {
    if (actual !== expected) {
        console.error(
            `ERROR: ${description}: expected '${expected}' but got '${actual}'`
        )
        process.exit(1)
    }
}

// A dereferenced package is a copy, so files removed from the package must be removed from the
// sandbox on the next sync, at any depth, or they remain resolvable there.
for (const protocol of ['ibazel', 'watch']) {
    resetPackage(['a.js', 'b.js', 'lib/deep.js', 'src/keep.js', 'src/gone.js'])
    const { devserver, sandbox, sync } = await newDevserver(protocol)
    await sync([STORE_ENTRY, LINK_ENTRY])
    check(
        `${protocol}: initial sync`,
        list(path.join(sandbox, STORE)),
        'a.js b.js lib/deep.js src/gone.js src/keep.js'
    )

    fs.rmSync(path.join(pkgOut, 'b.js'))
    fs.rmSync(path.join(pkgOut, 'lib'), { recursive: true })
    fs.rmSync(path.join(pkgOut, 'src', 'gone.js'))
    write(path.join(pkgOut, 'c.js'))
    if (protocol === 'ibazel') {
        await sync([STORE_ENTRY, LINK_ENTRY])
    } else {
        const cycle = { sources: { [`_main/${STORE}`]: { is_symlink: true } } }
        await devserver.cycleSyncRecurse(cycle, STORE, true, sandbox, false)
    }
    check(
        `${protocol}: re-sync after files are removed from the package`,
        list(path.join(sandbox, STORE)),
        'a.js c.js src/keep.js'
    )
}

// A node_modules link takes a different form depending on whether the entry it points at is synced:
// a symlink to that entry in the sandbox when it is, a copy of its contents when it is not. The link
// itself does not change in runfiles when the entries do, so it has to be re-evaluated regardless.
for (const protocol of ['ibazel', 'watch']) {
    resetPackage(['a.js'])
    const { devserver, sandbox } = await newDevserver(`${protocol}-transitions`)
    const link = path.join(sandbox, LINK)
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
    check(
        `${protocol}: link to a synced entry`,
        fs.lstatSync(link).isSymbolicLink(),
        true
    )

    // Its target is no longer synced, so it is dereferenced
    await resync(withoutEntry, null)
    check(
        `${protocol}: symlink replaced by a dereferenced directory`,
        fs.lstatSync(link).isDirectory() && list(link),
        'a.js'
    )

    // Its target is synced again, so it is a symlink again
    await resync(withEntry, { is_symlink: true })
    check(
        `${protocol}: dereferenced directory replaced by a symlink`,
        fs.lstatSync(link).isSymbolicLink(),
        true
    )

    // And dereferenced once more: files synced into it the first time must be synced again
    await resync(withoutEntry, null)
    check(
        `${protocol}: directory dereferenced a second time`,
        fs.lstatSync(link).isDirectory() && list(link),
        'a.js'
    )
}

fs.rmSync(base, { recursive: true, force: true })
