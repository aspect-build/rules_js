const worker_protocol = require('./worker')
const fs = require('fs/promises')
const path = require('path')

async function emit(request) {
    const output = request.arguments[0]
    const logger = new console.Console(request.output, request.output)
    logger.log('PI rule v.0.0.0')
    await fs.writeFile(output, Math.PI.toString())
    return 0
}

async function emitOnce() {
    const rawArgs = await fs.readFile(
        path.join('..', '..', '..', process.argv[2].replace('@', ''))
    )
    const args = rawArgs.toString().split('\n')
    emit({ arguments: args, output: process.stderr })
}

if (worker_protocol.isPersistentWorker(process.argv)) {
    worker_protocol.enterWorkerLoop(emit)
} else {
    emitOnce()
}
