const testLibDupes = require('@lib/test-dupes')

console.log('loaded dependency', testLibDupes.importDep().id())
console.log(
    'loaded duplicate aliased dependency',
    testLibDupes.importDupeDep().id()
)
