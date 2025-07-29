import chalk from 'chalk'
import lodash from 'lodash'
import { readFileSync } from 'fs'

// Test chalk replacement
const chalkPackageJsonDep = JSON.parse(readFileSync('./package.json', 'utf-8'))
    .dependencies['chalk']
if (chalkPackageJsonDep !== '5.3.0') {
    throw new Error(
        `Expected chalk version 5.3.0 declared in package.json, but got ${chalkPackageJsonDep}`
    )
}

const chalkActualDep = JSON.parse(
    readFileSync('./node_modules/chalk/package.json', 'utf-8')
).version
if (chalkActualDep !== '5.0.1') {
    throw new Error(
        `Expected chalk to be replaced with version 5.0.1, but got ${chalkActualDep}`
    )
}

// Test lodash replacement
const lodashPackageJsonDep = JSON.parse(readFileSync('./package.json', 'utf-8'))
    .dependencies['lodash']
if (lodashPackageJsonDep !== '4.17.21') {
    throw new Error(
        `Expected lodash version 4.17.21 declared in package.json, but got ${lodashPackageJsonDep}`
    )
}

const lodashActualDep = JSON.parse(
    readFileSync('./node_modules/lodash/package.json', 'utf-8')
).version
if (lodashActualDep !== '4.17.20') {
    throw new Error(
        `Expected lodash to be replaced with version 4.17.20, but got ${lodashActualDep}`
    )
}

// Test that both packages work functionally
const testArray = [1, 2, 2, 3, 3, 3]
const uniqueArray = lodash.uniq(testArray)
if (uniqueArray.length !== 3) {
    throw new Error(`Expected lodash.uniq to work, but got array length ${uniqueArray.length}`)
}

console.log(chalk.blue(`Hello world! Multiple package replacements work! 🎉`))
console.log(chalk.green(`Chalk ${chalkActualDep} and Lodash ${lodashActualDep} both replaced successfully`))
