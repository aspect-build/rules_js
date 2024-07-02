// NOTE: keep in sync with e2e/pnpm_workspace_rerooted

const packageJson = require('./package.json')
const libB = require('@lib/b')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    test: () => [libB.id()].join('\n'),
}
