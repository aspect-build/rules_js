const packageJson = require('./package.json')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    test: () =>
        [
            require('@aspect-test/d').version,
            require('alias-2/package.json').name,
        ].join('\n'),
}
