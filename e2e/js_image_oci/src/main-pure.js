const chalk = require('chalk')
const fs = require('fs')
const os = require('os')
const path = require('path')

const space = ' '
const art = fs.readFileSync(__dirname + '/ascii.art')

console.log(chalk.italic.green(art))
console.log(
    chalk.bold.bgRed(' OS '),
    space,
    chalk.redBright(process.platform, os.version(), os.arch())
)
console.log(
    chalk.bold.bgMagenta(' CWD '),
    space,
    chalk.magentaBright(process.cwd())
)
console.log('')

const pkgA = require('@mycorp/pkg-a')
console.log(`@mycorp/pkg-a acorn@${pkgA.getAcornVersion()}`)
console.log(`@mycorp/pkg-a uuid@${pkgA.getUuidVersion()}`)
console.log('')

const pkgB = require('@mycorp/pkg-b')
console.log(`@mycorp/pkg-b acorn@${pkgB.getAcornVersion()}`)
console.log(`@mycorp/pkg-b uuid@${pkgB.getUuidVersion()}`)
console.log('')

console.log(
    chalk.bold.bgYellow(' SOURCE CHECK '),
    space,
    chalk.yellowBright(
        fs.existsSync('source.txt')
    )
)
console.log(
    chalk.bold.bgMagenta(' DIRECTORY CHECK '),
    space,
    chalk.magentaBright(fs.existsSync('dir/source.txt'))
)
console.log(
    chalk.bold.bgMagenta(' SOURCE DIRECTORY CHECK '),
    space,
    chalk.magentaBright(
        fs.existsSync('srcdir/source.txt')
    )
)
console.log(
    chalk.bold.bgWhite(' PROTO CHECK '),
    space,
    chalk.whiteBright(
        fs.existsSync('google/cloud/speech/v1p1beta1/speech_proto-descriptor-set.proto.bin')
    )
)
