// Asserts *only non-dev* dependencies are available from the npm package

const assert = require('node:assert')
const fs = require('node:fs')
const path = require('node:path')

const packageStoreLink = process.argv
    .slice(2)
    .flatMap((arg) => arg.split(' '))
    .find(
        (arg) =>
            arg.includes('.aspect_rules_js') &&
            arg.endsWith('node_modules/@lib/test2')
    )
assert.ok(packageStoreLink, 'first-party package store link should be present')

const storeNodeModules = path.dirname(path.dirname(packageStoreLink))
for (const dep of ['@aspect-test/e', '@lib/test', 'alias-e']) {
    const depPath = path.join(storeNodeModules, dep)
    assert.ok(
        fs.existsSync(depPath),
        `${dep} should be linked into the first-party package store at ${depPath}`
    )
}

const testLib = require('@lib/test')
const testLib2 = require('@lib/test2')

console.log(
    'loaded dependency',
    testLib.importDep().id(),
    testLib2.importDep().id()
)
console.log(
    'loaded aliased dependency',
    testLib.importAliasedDep().id(),
    testLib2.importAliasedDep().id()
)

let e = null
try {
    testLib.importDevDep()
} catch (ex) {
    e = ex
}
if (e == null) {
    throw new Error('devDependency should NOT be available')
} else {
    console.log('devDependency not available')
}

let e2 = null
try {
    testLib.importAliasedDevDep()
} catch (ex) {
    e2 = ex
}
if (e2 == null) {
    throw new Error('devDependency should NOT be available')
} else {
    console.log('devDependency not available')
}

let e3 = null
try {
    testLib2.importDevDep()
} catch (ex) {
    e3 = ex
}
if (e3 == null) {
    console.error(
        'BUG: devDependency should NOT be available when linking js_library()'
    )
}

let e4 = null
try {
    testLib2.importAliasedDevDep()
} catch (ex) {
    e4 = ex
}
if (e4 == null) {
    console.error(
        'BUG: devDependency should NOT be available when linking js_library()'
    )
}

console.log('devDependency not available')
