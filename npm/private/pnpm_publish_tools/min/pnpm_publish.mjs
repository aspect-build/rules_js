import { spawnSync } from 'node:child_process'

const restArgs = process.argv.slice(2)

const spawn = spawnSync('pnpm', ['publish', '--no-git-checks', ...restArgs], {
  stdio: 'inherit',
})

process.exit(spawn.status)
