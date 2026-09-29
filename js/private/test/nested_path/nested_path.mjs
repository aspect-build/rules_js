import { spawnSync } from 'node:child_process'
import path from 'node:path'
import { runfiles } from '@bazel/runfiles'

const launcher = runfiles.resolve(process.argv[2])

// A fresh launch: no PATH, and none of this test's own launcher state.
const env = Object.fromEntries(
    Object.entries(process.env).filter(
        ([k]) => k !== 'PATH' && !k.startsWith('JS_BINARY__')
    )
)

const { status, stdout, stderr } = spawnSync(launcher, [], {
    encoding: 'utf8',
    env,
})
const match = /^inner PATH (.*)$/m.exec(stdout)
if (status !== 0 || !match) {
    process.stderr.write(
        `expected the nested js_binary to run, got exit code ${status} and:\n${stdout}${stderr}\n`
    )
    process.exit(1)
}

const entries = match[1].split(path.delimiter)
if (entries.includes('')) {
    process.stderr.write(`PATH has an empty entry: '${match[1]}'\n`)
    process.exit(1)
}

console.log(`nested js_binary ran with PATH ${match[1]}`)
