const chalk = require('chalk')
const fs = require('fs')
const os = require('os')
const path = require('path')

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
console.log('')

console.log(
    chalk.bold.bgYellow(' SOURCE CHECK '),
    space,
    chalk.yellowBright(
        fs.existsSync(
            path.join(process.env.JS_BINARY__RUNFILES, 'repo/source.txt')
        )
    )
)

console.log(
    chalk.bold.bgMagenta(' DIRECTORY CHECK '),
    space,
    chalk.magentaBright(
        fs.existsSync(
            path.join(process.env.JS_BINARY__RUNFILES, 'repo/dir/source.txt')
        )
    )
)

console.log(
    chalk.bold.bgMagenta(' SOURCE DIRECTORY CHECK '),
    space,
    chalk.magentaBright(
        fs.existsSync(
            path.join(process.env.JS_BINARY__RUNFILES, 'repo/srcdir/source.txt')
        )
    )
)

console.log(
    chalk.bold.bgWhite(' PROTO CHECK '),
    space,
    chalk.whiteBright(
        fs.existsSync(
            path.join(
                process.env.JS_BINARY__RUNFILES,
                'com_google_googleapis/google/cloud/speech/v1p1beta1/speech_proto-descriptor-set.proto.bin'
            )
        )
    )
)
