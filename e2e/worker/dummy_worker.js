const worker_protocol = require('./worker')
const fs = require('fs/promises')

async function emit(request) {
    const input = request.inputs[0]
    const output = request.arguments[0]
    const logger = new console.Console(request.output, request.output)
    logger.log('PI rule v.0.0.0')
    await fs.writeFile(output, Math.PI.toString())
    return 0
}

worker_protocol.enterWorkerLoop(emit)
