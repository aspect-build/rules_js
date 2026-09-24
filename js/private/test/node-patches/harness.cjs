// We don't want to bring jest into this repo so we just fake the describe and it functions here
exports.describe = async function describe(name, fn) {
    const unfinished = () => {
        console.error(`describe('${name}') did not finish`)
        process.exitCode = 1
    }
    // A suite whose promise never settles lets the event loop drain and exit 0; fail it instead.
    process.once('exit', unfinished)
    try {
        await fn()
    } finally {
        process.off('exit', unfinished)
    }
}

exports.it = async function it(_, fn) {
    await fn()
}
