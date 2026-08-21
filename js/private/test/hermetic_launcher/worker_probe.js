// Entry point for the worker-thread differential test. Node worker threads inherit
// execArgv, so whichever preload node was given runs again in the worker -- a second
// realm, with its own fs to patch and no ability to change directory. The two reports
// this writes must be byte-identical.

const fs = require('fs')
const path = require('path')
const { Worker } = require('worker_threads')

const out = process.argv[2]
const execroot = process.env.JS_BINARY__EXECROOT
const runfiles = process.env.JS_BINARY__RUNFILES

// The runfiles tree is named after the tool target, and the hermetic run's tool is the
// wrapper, so anything inside it is reported relative to its root.
function normalize(p) {
    if (!p) return null
    if (p === runfiles) return '<runfiles>'
    if (p.startsWith(runfiles + path.sep)) {
        return path.join('<runfiles>', path.relative(runfiles, p))
    }
    return path.relative(execroot, p)
}

const worker = new Worker(path.join(__dirname, 'worker_child.js'))

worker.on('error', (err) => {
    process.stderr.write(`FAIL: worker threw: ${err.stack}\n`)
    process.exit(1)
})

worker.on('message', (child) => {
    const report = {
        // This target sets chdir, so the launcher moved here before the worker started.
        main_cwd: path.relative(execroot, process.cwd()),

        // The worker has to inherit that, not repeat it: process.chdir throws
        // ERR_WORKER_UNSUPPORTED_OPERATION in a worker thread.
        worker_cwd: path.relative(execroot, child.cwd),

        // The fs patches are per realm, so the preload has to do its work again here.
        worker_fs_patched: child.fs_patched,
        worker_patch_roots: (child.patch_roots || '').split(':').map(normalize),
        worker_exec_path: normalize(child.exec_path),
    }

    fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n')

    // Same guard as the other differential tests: proves the two sides really ran
    // through different launchers.
    fs.writeFileSync(
        out.replace('report_', 'launcher_').replace('.json', '.txt'),
        path.basename(process.env.JS_BINARY__NODE_PATCHES) + '\n'
    )

    worker.terminate()
})
