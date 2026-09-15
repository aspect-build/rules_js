// A worker thread is handed node's original exec arguments, so a child spawned from a worker
// is the one place the launcher could potentially leak back into a child process and run a
// second launch against it.
import * as path from 'node:path'
import { Worker } from 'node:worker_threads'

const script = `
const { execFileSync } = require('node:child_process')
const { parentPort } = require('node:worker_threads')
const child = execFileSync(
    process.execPath,
    [...process.execArgv, '-e', 'console.log(process.env.PATH)'],
    { encoding: 'utf8' }
)
parentPort.postMessage({
    execArgv: process.execArgv,
    childPath: child.trim(),
    depth: process.env.JS_BINARY__NODE_PATCHES_DEPTH,
})
`

const {
    execArgv: workerExecArgv,
    childPath,
    depth: workerDepth,
} = await new Promise((resolve, reject) => {
    const worker = new Worker(script, { eval: true })
    worker.on('message', resolve)
    worker.on('error', reject)
    worker.on('exit', () =>
        reject(new Error('worker exited without a message'))
    )
})

console.log(
    `worker execArgv is bootstrap: ${path.basename(workerExecArgv[1] || '') === 'bootstrap.cjs'}`
)

// A worker on the exec path inherits node's whole command line, so the target's node options
// have to reach it as well as the preload. js_binary passes --preserve-symlinks-main by
// default, and a worker without it resolves its entry point out of the runfiles tree.
console.log(
    `worker keeps node options: ${workerExecArgv.includes('--preserve-symlinks-main')}`
)

// The exec arguments only say what the worker was asked to preload. A worker inherits a copy of
// the environment, so the depth the bootstrap bumps reads one deeper than the launch's own '.'
// only if the bootstrap actually ran in this thread.
console.log(`worker ran the bootstrap: ${workerDepth === '..'}`)

// A launch puts the node wrapper directory on the front of PATH. A child that re-ran the launcher
// would have done that a second time, so the directory would appear twice.
const wrapperDir = path.dirname(process.env.JS_BINARY__NODE_WRAPPER)
const hits = childPath
    .split(path.delimiter)
    .filter((dir) => dir === wrapperDir).length
console.log(`worker child path not doubled: ${hits === 1}`)
