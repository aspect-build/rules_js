import { spawn } from 'node:child_process'
import path from 'path'
import { fileURLToPath } from 'url'

const __esm_filename = fileURLToPath(import.meta.url)
const __esm_dirname = path.dirname(__esm_filename)

const child = spawn(
  'node',
  ['../node_modules/chalk/index.js'],
  {
    cwd: __esm_dirname,
  }
)

child.stdout.on('data', data => {
  console.log(`stdout: ${data}`)
})

child.stderr.on('data', data => {
  console.error(`stderr: ${data}`)
})

child.on('close', code => {
  console.log(`child process exited with code ${code}`)
})
