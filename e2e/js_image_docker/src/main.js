// const chalk = require('chalk')
// const fs = require('fs')
// const os = require('os')

// const space = ' '
// const art = fs.readFileSync(__dirname + '/ascii.art')

// console.log(chalk.italic.green(art))
// console.log(
//     chalk.italic.bgBlue(' WORKSPACE '),
//     space,
//     chalk.blueBright(process.env.JS_BINARY__WORKSPACE)
// )
// console.log(
//     chalk.bold.bgGreen(' TARGET '),
//     space,
//     chalk.greenBright(process.env.JS_BINARY__TARGET)
// )
// console.log(
//     chalk.bold.bgGray(' ARCH/CPU '),
//     space,
//     chalk.gray(process.env.JS_BINARY__TARGET_CPU)
// )
// console.log(
//     chalk.bold.bgRed(' OS '),
//     space,
//     chalk.redBright(process.platform, os.version(), os.arch())
// )

import { spawn } from 'node:child_process'
import path from 'path'
import { fileURLToPath } from 'url'

/**
 * NOTE(david.aghassi) - ESM doesn't have the concept
 * of `__dirname` or `__filename` global variables like commonjs
 * This logic allows us to use that older syntax
 * while leveraging the built-ins provided by ESM
 */
const __esm_filename = fileURLToPath(import.meta.url)
const __esm_dirname = path.dirname(__esm_filename)

const playwright = spawn(
  'node',
  ['../node_modules/chalk/index.js'],
  {
    cwd: __esm_dirname,
  }
)

playwright.stdout.on('data', data => {
  console.log(`stdout: ${data}`)
})

playwright.stderr.on('data', data => {
  console.error(`stderr: ${data}`)
})

playwright.on('close', code => {
  console.log(`child process exited with code ${code}`)
})
