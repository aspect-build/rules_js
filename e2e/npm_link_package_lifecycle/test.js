const chalk = require('@e2e/lib')

if (typeof chalk.red !== 'function') {
    throw new Error('expected @e2e/lib to export chalk')
}
