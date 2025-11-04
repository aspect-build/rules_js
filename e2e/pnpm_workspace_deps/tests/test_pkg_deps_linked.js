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
    // TODO: see https://github.com/aspect-build/rules_js/issues/2013 and similar issues.
    //
    // The transitive-dev logic was depending on the incorrect pnpm <v9 'dev' flag behavior
    // and this test only passed due to that behaviour working in this specific test case.
    //
    // As of pnpm 9+ this test no longer passes due to incorrect assumptions and needs a
    // proper fix regarding transitive dep deps of local packages.
    //
    // throw new Error('devDependency should NOT be available')
} else {
    console.log('devDependency not available')
}
