console.log(JSON.stringify(require('@aspect-test/a/package.json'), null, 2))
console.log(require.resolve('@aspect-test/a'))
const a = require('@aspect-test/a')
console.log(a.id())
console.log(a.idB())
console.log(a.idC())
console.log(a.idD())
