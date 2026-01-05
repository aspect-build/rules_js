import { fileURLToPath } from 'url'
import { dirname } from 'node:path'
import { data2, data3, my__dirname, my__filename, my__pwd } from './lib.mjs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

console.log('process.cwd():', my__pwd)
console.log('data2:', data2)
console.log('data3:', data3)

if (my__dirname !== __dirname) {
    throw new Error('__dirname does not match expected value')
}

if (my__pwd !== process.cwd()) {
    throw new Error('process.cwd() does not match expected value')
}

if (dirname(my__filename) !== dirname(__filename)) {
    throw new Error('__filename does not match expected value')
}

if (
    dirname(__filename) !=
    dirname(fileURLToPath(import.meta.resolve('./lib2.mjs')))
) {
    throw new Error('import.meta.resolve does not match expected value')
}
