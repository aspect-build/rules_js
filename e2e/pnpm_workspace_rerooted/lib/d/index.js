const packageJson = require('./package.json')
const a2 = require('alias-2/package.json')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    test: () => [a2.name].join('\n'),
}
