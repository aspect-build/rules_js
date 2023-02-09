// Asserts *only non-dev* dependencies are available from the npm package

const testLib = require('@lib/test')

console.log('loaded dependency', testLib.importDep().id())

let e = null
try {
    testLib.importDevDep()
} catch (ex) {
    e = ex
}
if (e == null) {
    throw new Error('devDependency should NOT be available')
}
console.log('devDependency not available')
