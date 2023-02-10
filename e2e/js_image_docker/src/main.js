const chalk = require('chalk')
const fs = require('fs')
const os = require('os')

const space = ' '
const art = fs.readFileSync(__dirname + '/ascii.art')

console.log(chalk.italic.green(art))
console.log(
    chalk.italic.bgBlue(' WORKSPACE '),
    space,
    chalk.blueBright(process.env.JS_BINARY__WORKSPACE)
)
console.log(
    chalk.bold.bgGreen(' TARGET '),
    space,
    chalk.greenBright(process.env.JS_BINARY__TARGET)
)
console.log(
    chalk.bold.bgGray(' ARCH/CPU '),
    space,
    chalk.gray(process.env.JS_BINARY__TARGET_CPU)
)
console.log(
    chalk.bold.bgRed(' OS '),
    space,
    chalk.redBright(process.platform, os.version(), os.arch())
)
