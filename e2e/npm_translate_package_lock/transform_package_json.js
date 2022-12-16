// A "preupdate" script to pass to the `npm_translate_lock` repository rule which renames the
// package.json the npm specific "overrides" field to "pnpm.overrides" which pnpm understands and
// can use when calling `pnpm import` to update the pnpm-lock.yaml file
const fs = require('fs')
const packageJson = require('./package.json')
packageJson.pnpm = {
    overrides: packageJson.overrides,
}
delete packageJson.overrides
fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2), 'utf-8')
console.log(fs.readFileSync('package.json', 'utf-8'))
