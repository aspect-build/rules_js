const packageJson = require('./package.json')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
}
