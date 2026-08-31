import { spawnSync } from 'node:child_process'

const restArgs = process.argv.slice(2)

const spawn = spawnSync('npm', ['publish', ...restArgs], {
    stdio: 'inherit',
})

// A spawn that never ran has no status to exit with, and exiting with null is exiting 0, which
// would report a publish that did not happen as a success.
if (spawn.error) {
    console.error(`ERROR: could not run npm publish: ${spawn.error.message}`)
    process.exit(1)
}

process.exit(spawn.status ?? 1)
