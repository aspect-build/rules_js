#!/usr/bin/env node
import { resolve } from 'node:path'
import { writeFileSync } from 'node:fs'
import { createIntegrityManifest } from './pnp_verify.mjs'

let root = '.'
let cacheRoot = '.yarn/cache'
let output = null
for (let index = 2; index < process.argv.length; index += 1) {
    if (process.argv[index] === '--root' && process.argv[index + 1])
        root = process.argv[++index]
    else if (process.argv[index] === '--cache-root' && process.argv[index + 1])
        cacheRoot = process.argv[++index]
    else if (process.argv[index] === '--output' && process.argv[index + 1])
        output = process.argv[++index]
    else {
        console.error(
            'usage: pnp_integrity [--root <project>] [--cache-root <project-relative-directory>] [--output <file>]'
        )
        process.exit(64)
    }
}

const content = `${JSON.stringify(
    createIntegrityManifest(resolve(root), { cacheRoot }),
    null,
    2
)}\n`
if (output) writeFileSync(resolve(output), content)
else process.stdout.write(content)
