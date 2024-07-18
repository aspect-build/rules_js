// Asserts all dependencies are available directly from the file

const testLib = require('../linked_pkg/index')
const testLib2 = require('../linked_lib/index')

console.log(
    'loaded dependency',
    testLib.importDep().id(),
    testLib2.importDep().id()
)
console.log(
    'loaded devDependency',
    testLib.importDevDep().id(),
    testLib2.importDevDep().id()
)
console.log(
    'loaded aliased dependency',
    testLib.importAliasedDep().id(),
    testLib2.importAliasedDep().id()
)
