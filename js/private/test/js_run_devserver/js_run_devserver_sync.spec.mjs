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
    const devserver = await import(
        '../../devserver/js_run_devserver.mjs?nopatch'
    )
    let error = null
    try {
        devserver.applyConfig({ package_store_mode: 'sandbox' }, '0')
    } catch (e) {
        error = e
    }
    check('applyConfig without fs patches throws', !!error, true)
    devserver.applyConfig({ package_store_mode: 'execroot' }, '0')
}

// Syncs a list of entries the way a protocol does after a build. `sources` is what the watch
// protocol reports as changed; without it, the watch protocol resyncs everything.
async function resync(devserver, protocol, sandbox, config, files, sources) {
    const entriesPath = path.join(sandbox, '..', 'entries.json')
    fs.writeFileSync(entriesPath, JSON.stringify(files))
    if (protocol === 'ibazel') {
        await devserver.ibazelBuildCompleted(config, entriesPath, sandbox)
    } else {
        await devserver.watchProtocolCycle(
            config,
            entriesPath,
            sandbox,
            sources === undefined
                ? { kind: 'CYCLE_RESET', sources: {} }
                : { kind: 'CYCLE', sources }
        )
    }
}

// Determines if a link resolves to a target
function resolvesTo(link, target) {
    return (
        fs.existsSync(link) &&
        fs.realpathSync(link) === fs.realpathSync(target)
    )
}

// A node_modules link keeps its relative target, so it resolves inside the sandbox when its target
// is synced there. The node_modules entries are synced from the list of entries, also when a watch
// cycle reports no change to them.
for (const protocol of ['ibazel', 'watch']) {
    const { devserver, sandbox } = await newDevserver(protocol)
    const link = path.join(sandbox, LINK)
    const inSandbox = () => resolvesTo(link, path.join(sandbox, STORE))
    const withEntry = [STORE_ENTRY, LINK_ENTRY]
    const withoutEntry = [LINK_ENTRY]
    const config = {}
    const sync = (files) =>
        resync(devserver, protocol, sandbox, config, files, {})

    await resync(devserver, protocol, sandbox, config, withEntry)
    check(`${protocol}: link to a synced entry`, inSandbox(), true)
    check(
        `${protocol}: link target relative`,
        path.isAbsolute(fs.readlinkSync(link)),
        false
    )
    check(
        `${protocol}: package copied`,
        fs.readFileSync(path.join(link, 'a.js'), 'utf8'),
        path.join(main, STORE, 'a.js')
    )

    await sync(withoutEntry)
    check(`${protocol}: entry no longer synced`, inSandbox(), false)
    check(
        `${protocol}: package removed`,
        fs.existsSync(path.join(sandbox, STORE)),
        false
    )

    await sync(withEntry)
    check(`${protocol}: entry synced again`, inSandbox(), true)

    // An unchanged link is left alone rather than recreated
    const before = fs.lstatSync(link, { bigint: true }).ino
    await sync(withEntry)
    check(
        `${protocol}: unchanged link kept`,
        fs.lstatSync(link, { bigint: true }).ino,
        before
    )
}

// Bazel replaces a package directory as a whole when it rebuilds it, rather than changing it in
// place, for example when a patch that rules_js applies to the package changes. The sandbox copy is
// replaced as a whole too, so files removed from the package are not left behind at any depth.
for (const protocol of ['ibazel', 'watch']) {
    const store = `node_modules/.aspect_rules_js/${protocol}@1.0.0/node_modules/${protocol}`
    const pkg = path.join(main, store)
    for (const f of ['a.js', 'b.js', 'lib/deep.js', 'src/keep.js', 'src/gone.js']) {
        write(path.join(pkg, f))
    }
    const { devserver, sandbox } = await newDevserver(`${protocol}-rebuilt`)
    const config = {}
    const entries = [[store, 1]]
    await resync(devserver, protocol, sandbox, config, entries)
    check(
        `${protocol}: package copied`,
        list(path.join(sandbox, store)),
        'a.js b.js lib/deep.js src/gone.js src/keep.js'
    )

    // Unchanged packages are not copied again
    write(path.join(sandbox, store, 'marker.js'))
    await resync(devserver, protocol, sandbox, config, entries, {})
    check(
        `${protocol}: unchanged package not copied again`,
        fs.existsSync(path.join(sandbox, store, 'marker.js')),
        true
    )

    fs.rmSync(pkg, { recursive: true })
    for (const f of ['a.js', 'c.js', 'src/keep.js']) {
        write(path.join(pkg, f))
    }
    await resync(devserver, protocol, sandbox, config, entries, {
        [`_main/${store}`]: {},
    })
    check(
        `${protocol}: rebuilt package replaces its copy`,
        list(path.join(sandbox, store)),
        'a.js c.js src/keep.js'
    )
    check(
        `${protocol}: no copies left beside the rebuilt package`,
        fs.readdirSync(path.dirname(path.join(sandbox, store))).join(' '),
        protocol
    )
}

// A package can change between a directory and a link, for example when a dependency on an npm
// package is replaced with one on a first-party package.
for (const protocol of ['ibazel', 'watch']) {
    const store = `node_modules/.aspect_rules_js/${protocol}-kind@1.0.0/node_modules/${protocol}-kind`
    const source = `${protocol}-kind-src`
    write(path.join(main, store, 'index.js'))
    write(path.join(main, source, 'index.js'))
    const { devserver, sandbox } = await newDevserver(`${protocol}-kind`)
    const config = {}
    const entries = [
        [store, 1],
        [`${source}/index.js`, 0],
    ]
    await resync(devserver, protocol, sandbox, config, entries)
    check(
        `${protocol}: package directory copied`,
        fs.lstatSync(path.join(sandbox, store)).isDirectory(),
        true
    )

    fs.rmSync(path.join(main, store), { recursive: true })
    symlink(
        path.relative(path.join(main, path.dirname(store)), path.join(main, source)),
        path.join(main, store)
    )
    await resync(devserver, protocol, sandbox, config, entries, {
        [`_main/${store}`]: { is_symlink: true },
    })
    check(
        `${protocol}: package directory replaced with a link`,
        resolvesTo(path.join(sandbox, store), path.join(sandbox, source)),
        true
    )
    check(
        `${protocol}: no copies left beside the replaced package`,
        fs.readdirSync(path.dirname(path.join(sandbox, store))).join(' '),
        `${protocol}-kind`
    )
}

// A devserver defined in another repository syncs files whose paths start with ../<repo>/, which the
// sandbox places beside the main repository as the runfiles tree does. Links between its packages
// stay within the sandbox like those of the main repository.
{
    const repo = path.join(runfiles, 'other_repo')
    const store =
        '../other_repo/node_modules/.aspect_rules_js/dep@1.0.0/node_modules/dep'
    const link = '../other_repo/app/node_modules/dep'
    write(path.join(main, store, 'index.js'))
    symlink(
        path.relative(
            path.join(main, path.dirname(link)),
            path.join(main, store)
        ),
        path.join(main, link)
    )
    const { devserver, sandbox } = await newDevserver('other-repo')
    await resync(devserver, 'ibazel', sandbox, {}, [
        [store, 1],
        [link, 0],
    ])
    check(
        'link in another repository points at its target in the sandbox',
        resolvesTo(path.join(sandbox, link), path.join(sandbox, store)),
        true
    )
    check(
        'package in another repository copied into the sandbox',
        fs.existsSync(path.join(sandbox, store, 'index.js')),
        true
    )
    fs.rmSync(repo, { recursive: true, force: true })
}

// A link to a target outside the runfiles tree keeps its absolute target, since a relative one
// would resolve to an unrelated path outside the sandbox.
{
    const outside = path.join(base, 'outside')
    const link = 'app/node_modules/outside'
    write(path.join(outside, 'index.js'))
    symlink(outside, path.join(main, link))
    const { devserver, sandbox } = await newDevserver('outside')
    await resync(devserver, 'ibazel', sandbox, {}, [[link, 0]])
    check(
        'link outside the runfiles tree kept absolute',
        fs.readlinkSync(path.join(sandbox, link)),
        outside
    )
}

// A file that a watch cycle reports as deleted is removed from the sandbox, also when the same
// cycle adds or removes entries.
{
    const dir = 'app/lib'
    const deleted = `${dir}/deleted.js`
    const added = 'app/added_with_deletion.js'
    write(path.join(main, deleted))
    write(path.join(main, added))
    const { devserver, sandbox } = await newDevserver('cycle-deletion')
    const entriesPath = path.join(base, 'cycle-deletion-entries.json')
    const config = {}
    fs.writeFileSync(entriesPath, JSON.stringify([[dir, 1]]))
    await devserver.watchProtocolCycle(config, entriesPath, sandbox, {
        kind: 'CYCLE_RESET',
        sources: {},
    })
    check(
        'cycle-deletion: file under a directory entry synced',
        fs.existsSync(path.join(sandbox, deleted)),
        true
    )

    fs.rmSync(path.join(main, deleted))
    fs.writeFileSync(
        entriesPath,
        JSON.stringify([
            [dir, 1],
            [added, 0],
        ])
    )
    await devserver.watchProtocolCycle(config, entriesPath, sandbox, {
        kind: 'CYCLE',
        sources: { [`_main/${deleted}`]: null, [`_main/${added}`]: {} },
    })
    check(
        'cycle-deletion: added entry synced',
        fs.existsSync(path.join(sandbox, added)),
        true
    )
    check(
        'cycle-deletion: deleted file removed from the sandbox',
        fs.existsSync(path.join(sandbox, deleted)),
        false
    )
}

fs.rmSync(base, { recursive: true, force: true })
