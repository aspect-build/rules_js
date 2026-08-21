// Entry point for the ESM execroot differential test. node resolves an ESM main through
// its ESM loader, which never consults the CJS hook launcher.cjs installs for a CJS main,
// so this is the target that says the ESM half of the redirect works. If it did not fire,
// import.meta.url below would name the runfiles copy and the report would stop matching
// the one the launcher script produces.

import * as fs from 'node:fs'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'

const execroot = process.env.JS_BINARY__EXECROOT
const runfiles = process.env.JS_BINARY__RUNFILES
const bindir = process.env.BAZEL_BINDIR

const out = process.argv[2]
const launcherOut = out.replace('report_', 'launcher_').replace('.json', '.txt')

// Same normalization as action_probe.js: which tree a path is in, not where it is on this
// machine, since the two launchers reach the same file through differently-named roots.
function normalize(p) {
    if (!p) {
        return null
    }
    const bindirRoot = path.join(execroot, bindir)
    for (const [name, root] of [
        ['<runfiles>', runfiles],
        ['<bindir>', bindirRoot],
        ['<execroot>', execroot],
    ]) {
        if (p === root || p.startsWith(root + path.sep)) {
            return path.posix.join(name, path.relative(root, p))
        }
    }
    return p
}

const report = {
    cwd_is_bindir: process.cwd() === path.join(execroot, bindir),

    // An ESM module has no require.main and no module.paths to inspect, so its own URL is
    // the evidence: it is the copy node actually loaded, and therefore the directory it
    // resolves bare specifiers from.
    entry_point: normalize(process.argv[1]),
    import_meta_path: normalize(fileURLToPath(import.meta.url)),

    argv_after_out: process.argv.slice(3),
    argv_has_bazel_bindir: process.argv.includes('--bazel-bindir'),
}

fs.mkdirSync(path.dirname(out), { recursive: true })
fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n')
fs.writeFileSync(launcherOut, path.basename(process.env.JS_BINARY__NODE_PATCHES) + '\n')
