const { chalk } = require('chalk')

function lib_a() {
    return chalk.blue('lib_a')
}

module.exports = {
    lib_a,
}
