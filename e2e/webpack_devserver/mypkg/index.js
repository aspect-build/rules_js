const packageJson = require('./package.json')
const chalk = require('chalk')
module.exports = {
    name: () => chalk.blue(packageJson.name),
}
