// Asserts that js_binary(chdir) lands the process in the right directory and that nothing
// downstream of the process re-applies it. The move is done by bootstrap.cjs, which every
// node process in the tree preloads, so a child node process and a worker thread are the
// two places a second, compounding chdir could creep in.
import { spawnSync } from 'node:child_process'
import * as path from 'node:path'
import { Worker } from 'node:worker_threads'

const cwd = process.cwd()

function check(what, actual, expected) {
    if (actual !== expected) {
        console.error(`FAIL: ${what}: expected '${expected}', got '${actual}'`)
        process.exitCode = 1
    }
}

// argv[2], when given, is a slash-separated path that the cwd must end with. It is omitted
// when the chdir does not move us anywhere in particular, such as chdir = ".".
const expectedSuffix = process.argv[2]?.split('/').join(path.sep)
if (expectedSuffix && !cwd.endsWith(expectedSuffix)) {
    console.error(`FAIL: cwd '${cwd}' does not end with '${expectedSuffix}'`)
    process.exitCode = 1
}

check('process.env.PWD', process.env.PWD, cwd)

// bootstrap.cjs consumes JS_BINARY__CHDIR when it applies it.
check('process.env.JS_BINARY__CHDIR', process.env.JS_BINARY__CHDIR, undefined)

// A child node process re-enters bootstrap.cjs through the node wrapper's --require. It
// already inherits this cwd, so a relative chdir must not be applied a second time.
const child = spawnSync('node', ['-e', 'console.log(process.cwd())'], {
    encoding: 'utf8',
})
if (child.status !== 0) {
    console.error(`FAIL: child exited ${child.status}: ${child.stderr}`)
    process.exitCode = 1
}
check('child cwd', child.stdout.trim(), cwd)

// Preloads run in worker threads too, where process.chdir() throws outright.
const workerCwd = await new Promise((resolve, reject) => {
    const worker = new Worker(
        "require('node:worker_threads').parentPort.postMessage(process.cwd())",
        { eval: true }
    )
    worker.on('message', resolve)
    worker.on('error', reject)
    worker.on('exit', () =>
        reject(new Error('worker exited without a message'))
    )
})
check('worker cwd', workerCwd, cwd)

console.log(`cwd: ${cwd}`)
