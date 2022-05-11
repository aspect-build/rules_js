const packageJson = require('./package.json')
const e = require('@aspect-test/e')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? package.version : '0.0.0'
        }`,
    idE: () => e.id(),
}
