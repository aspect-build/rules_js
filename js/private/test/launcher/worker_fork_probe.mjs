// A worker thread is handed node's original exec arguments rather than the array launcher.cjs
// rewrote for its children, so a child spawned from a worker is the one place the launcher can
// leak back into a child process and run a second launch against it.
//
// Each line is a separate assert_contains in BUILD.bazel, so one failure names the invariant it
// broke.
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
parentPort.postMessage({ execArgv: process.execArgv, childPath: child.trim() })
`

const { execArgv: workerExecArgv, childPath } = await new Promise(
    (resolve, reject) => {
        const worker = new Worker(script, { eval: true })
        worker.on('message', resolve)
        worker.on('error', reject)
        worker.on('exit', () =>
            reject(new Error('worker exited without a message'))
        )
    }
)

console.log(
    `worker execArgv is bootstrap: ${path.basename(workerExecArgv[1] || '') === 'bootstrap.cjs'}`
)

// A launch puts the node wrapper directory on the front of PATH. A child that re-ran the launcher
// would have done that a second time, so the directory would appear twice.
const wrapperDir = path.dirname(process.env.JS_BINARY__NODE_WRAPPER)
const hits = childPath
    .split(path.delimiter)
    .filter((dir) => dir === wrapperDir).length
console.log(`worker child path not doubled: ${hits === 1}`)
