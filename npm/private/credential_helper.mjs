// Asks a Bazel credential helper (https://bazel.build/reference/command-line-reference#flag--credential_helper)
// for the Authorization header of each registry URL and prints a JSON object of {url: header}.
//
// Usage: node credential_helper.mjs <helper> <url>...
import { spawnSync } from 'node:child_process'

const [helper, ...urls] = process.argv.slice(2)
const headers = {}

for (const url of urls) {
    const result = spawnSync(helper, ['get'], {
        input: JSON.stringify({ uri: url }),
        encoding: 'utf8',
    })
    if (result.error) {
        throw result.error
    }
    if (result.status !== 0) {
        process.stderr.write(result.stderr)
        process.exit(result.status ?? 1)
    }

    const response = JSON.parse(result.stdout).headers ?? {}
    const name = Object.keys(response).find(
        (h) => h.toLowerCase() === 'authorization'
    )
    if (name && response[name].length) {
        headers[url] = response[name][0]
    }
}

process.stdout.write(JSON.stringify(headers))
