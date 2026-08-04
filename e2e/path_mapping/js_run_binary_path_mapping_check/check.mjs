import { writeFileSync } from 'fs'

const outFile = process.argv[2]
if (!outFile) {
    process.stderr.write('Usage: check.mjs <output-file>\n')
    process.exit(1)
}

const bindir = process.env.BAZEL_BINDIR
if (bindir !== 'bazel-out/cfg/bin') {
    process.stderr.write(
        `Expected BAZEL_BINDIR to be "bazel-out/cfg/bin", got "${bindir}"\n`
    )
    process.exit(1)
}

const leaked = process.argv.filter((arg) => arg === '--bazel-bindir')
if (leaked.length > 0) {
    process.stderr.write(`--bazel-bindir flag leaked into argv: ${leaked}\n`)
    process.exit(1)
}

writeFileSync(outFile, 'OK\n')
