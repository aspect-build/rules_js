const packageJson = require('./package.json')
const libB = require('@lib/b')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    idLibB: () => libB.id(),
}
