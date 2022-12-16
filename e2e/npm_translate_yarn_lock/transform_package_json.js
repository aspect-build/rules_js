// A "preupdate" script to pass to the `npm_translate_lock` repository rule which transforms the
// package.json "resolutions" entries that have yarn specific syntax to a format which pnpm
// understands and can use when calling `pnpm import` to update the pnpm-lock.yaml file
const fs = require('fs')
const packageJson = require('./package.json')
const resolutionsTransforms = {
    '**/@types/node': '@types/node',
}
resolutions = Object.keys(packageJson.resolutions)
for (const k of Object.keys(resolutionsTransforms)) {
    if (resolutions.includes(k)) {
        packageJson.resolutions[resolutionsTransforms[k]] =
            packageJson.resolutions[k]
        delete packageJson.resolutions[k]
    }
}
fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2), 'utf-8')
console.log(fs.readFileSync('package.json', 'utf-8'))
