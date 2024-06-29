const packageJson = require('./package.json')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    test: () =>
        [
            require('alias-2/package.json').name,
            require('@aspect-test/d').version,
        ].join('\n'),
}
