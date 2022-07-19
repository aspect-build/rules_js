const packageJson = require('./package.json')
const f = require('@aspect-test/f')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    idF: () => f.id(),
}
