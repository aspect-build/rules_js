console.log(process.argv)
const a = require('@aspect-test/a')
console.log('--a--')
console.log(a.id())
console.log(a.idB())
console.log(a.idC())
const b = require('@aspect-test/b')
console.log('--b--')
console.log(b.id())
console.log(b.idA())
console.log(b.idC())
const c = require('@aspect-test/c')
console.log('--c--')
console.log(c.id())
const fp = require('@e2e/lib')
console.log('--@e2e/lib--')
console.log(fp.id())
const rulesFooA = require('../../rules_foo/foo/node_modules/@aspect-test/a')
console.log('--rulesFooA--')
console.log(rulesFooA.id())
console.log(rulesFooA.idB())
console.log(rulesFooA.idC())
