// Runs in a node worker thread, which inherits execArgv and therefore the preload.

const fs = require('fs')
const { parentPort } = require('worker_threads')

parentPort.postMessage({
    cwd: process.cwd(),
    fs_patched: Boolean(fs._unpatched),
    patch_roots: process.env.JS_BINARY__FS_PATCH_ROOTS,
    exec_path: process.execPath,
})
