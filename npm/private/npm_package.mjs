import { spawnSync } from 'node:child_process'
import fs from 'node:fs'

const PACKAGE_DIR = `${process.env.JS_BINARY__RUNFILES}/{{PACKAGE_DIR}}`
const restArgs = process.argv.slice(2)

const spawn = spawnSync('npm', ['publish', PACKAGE_DIR, ...restArgs], {
    stdio: 'inherit',
})

console.log('npm', ['publish', PACKAGE_DIR, ...restArgs], { stdio: 'inherit' })
console.log(fs.readdirSync(PACKAGE_DIR))

process.exit(spawn.status)
