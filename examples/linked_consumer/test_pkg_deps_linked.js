// Asserts *only non-dev* dependencies are available from the npm package

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
}

let e2 = null
try {
    testLib2.importDevDep()
} catch (ex) {
    e2 = ex
}
if (e2 == null) {
    console.error(
        'BUG: devDependency should NOT be available when linking js_library()'
    )
}

console.log('devDependency not available')
