const packageJson = require('./package.json')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? package.version : '0.0.0'
        }`,
}
