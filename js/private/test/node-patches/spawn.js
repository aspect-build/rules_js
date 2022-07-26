const child_process = require('child_process')

const printbinjs = process.argv[2]
const printbinsh = process.argv[3]

// We don't want to bring jest into this repo so we just fake the describe and it functions here
async function describe(_, fn) {
    await fn()
}
async function it(_, fn) {
    await fn()
}

describe('child_process', async () => {
    function assertResult({ stdout, stderr, code, error }) {
        // Process errors
        if (stderr?.toString().trim()) {
            throw new Error(`Received stderr: ${stderr.toString()}`)
        } else if (code) {
            throw new Error(`Exit code: ${code}`)
        } else if (error) {
            throw new Error(`Error: ${error}`)
        }

        const nodePath = stdout.toString().trim()

        // NdoeJS path
        if (nodePath !== process.execPath) {
            throw new Error(
                `Expected: ${process.execPath}\n Actual: ${nodePath}`
            )
        }

        return nodePath
    }

    function testAsync(cp) {
        return new Promise((resolve, reject) => {
            let stdout = '',
                stderr = ''
            cp.stdout.on('data', (moreOut) => (stdout += moreOut))
            cp.stderr.on('data', (moreError) => (stderr += moreError))

            cp.on('error', reject)
            cp.on('close', (code) => {
                try {
                    resolve(assertResult({ stdout, stderr, code }))
                } catch (e) {
                    reject(e)
                }
            })
        })
    }

    function testSync(cp) {
        return assertResult(cp)
    }

    function createAssertCallback(resolve, reject) {
        return (error, stdout, stderr) => {
            try {
                resolve(assertResult({ stdout, stderr, error }))
            } catch (e) {
                reject(e)
            }
        }
    }

    await it('should launch patched node via child_process.execSync("node")', () => {
        testSync({ stdout: child_process.execSync(`node ${printbinjs}`) })
    })

    await it('should launch patched node via child_process.spawnSync("node")', () => {
        testSync(child_process.spawnSync('node', [printbinjs]))
    })

    await it('should launch patched node via child_process.spawn("node")', async () => {
        await testAsync(child_process.spawn('node', [printbinjs]))
    })

    await it('should launch patched node via child_process.spawn("node") with {shell: true}', async () => {
        await testAsync(
            child_process.spawn('node', [printbinjs], { shell: true })
        )
    })

    await it('should launch patched node via child_process.fork()', async () => {
        await testAsync(child_process.fork(printbinjs, { stdio: 'pipe' }))
    })

    await it('should launch patched node via child_process.exec("node")', async () => {
        await new Promise((resolve, reject) =>
            child_process.exec(
                `node ${printbinjs}`,
                createAssertCallback(resolve, reject)
            )
        )
    })

    if (process.platform == 'linux') {
        // TODO: enable this case on macos; it doesn't have realpath installed
        await it('should return patched node via exec(`which node`)', async () => {
            await new Promise((resolve, reject) =>
                child_process.exec(
                    'realpath `which node`',
                    createAssertCallback(resolve, reject)
                )
            )
        })
    }

    if (process.platform == 'linux') {
        // TODO: enable this case on macos; it doesn't have realpath installed
        await it('should launch patched node via child_process.execFile()', async () => {
            await new Promise((resolve, reject) =>
                child_process.execFile(
                    printbinsh,
                    createAssertCallback(resolve, reject)
                )
            )
        })
    }

    if (process.platform == 'linux') {
        // TODO: enable this case on macos; it doesn't have realpath installed
        await it('should launch patched node via child_process.execFileSync()', () => {
            testSync({ stdout: child_process.execFileSync(printbinsh) })
        })
    }
})
