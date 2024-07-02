// NOTE: keep in sync with e2e/pnpm_workspace_rerooted

const packageJson = require('./package.json')
const e = require('@aspect-test/e')
const libB = require('@lib/b')
const vendoredA = require('vendored-a')
const vendoredB = require('vendored-b')
module.exports = {
    id: () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`,
    test: () => [e.id(), libB.id(), vendoredA.id(), vendoredB.id()].join(','),
}
