import chalk from 'chalk'
import { readFileSync } from 'fs'

const packageJsonDep = JSON.parse(readFileSync('./package.json', 'utf-8'))
    .dependencies['chalk']
if (packageJsonDep !== '5.3.0') {
    throw new Error(
        `Expected chalk version 5.3.0 declared in package.json, but got ${pkgDep}`
    )
}

const actualDep = JSON.parse(
    readFileSync('./node_modules/chalk/package.json', 'utf-8')
).version
if (actualDep !== '5.0.1') {
    throw new Error(
        `Expected chalk to be replaced with version 5.0.1, but got ${actualDep}`
    )
}

console.log(chalk.blue(`Hello world! The meaning of life is... 42`))
