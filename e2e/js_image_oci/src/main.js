const chalk = require('chalk')
const fs = require('fs')
const os = require('os')
const { Runfiles } = require('@bazel/runfiles')

const runfiles = new Runfiles(process.env)

function runfileExists(rlocation) {
    try {
        return fs.existsSync(runfiles.resolve(rlocation))
    } catch {
        return false
    }
}

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
console.log(
    chalk.bold.bgMagenta(' CWD '),
    space,
    chalk.magentaBright(process.cwd())
)
console.log(
    chalk.bold.bgCyan(' JS_BINARY__RUNFILES '),
    space,
    chalk.cyanBright(process.env.JS_BINARY__RUNFILES)
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
    chalk.yellowBright(runfileExists('repo/source.txt'))
)
console.log(
    chalk.bold.bgMagenta(' DIRECTORY CHECK '),
    space,
    chalk.magentaBright(runfileExists('repo/dir/source.txt'))
)
console.log(
    chalk.bold.bgMagenta(' SOURCE DIRECTORY CHECK '),
    space,
    chalk.magentaBright(runfileExists('repo/srcdir/source.txt'))
)
console.log(
    chalk.bold.bgWhite(' PROTO CHECK '),
    space,
    chalk.whiteBright(
        runfileExists(
            'com_google_googleapis/google/cloud/speech/v1p1beta1/speech_proto-descriptor-set.proto.bin'
        )
    )
)
