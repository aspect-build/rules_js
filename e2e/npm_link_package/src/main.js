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
const wrapper = require('@e2e/wrapper-lib')
console.log('--@e2e/wrapper-lib--')
console.log(wrapper.id())
console.log(wrapper.libId())
console.log(wrapper.subdirId())
const rulesFooA = require('../../foo/node_modules/@aspect-test/a')
console.log('--rulesFooA--')
console.log(rulesFooA.id())
console.log(rulesFooA.idB())
console.log(rulesFooA.idC())
const sharp = require('sharp')
const roundedCorners = Buffer.from(
    '<svg><rect x="0" y="0" width="200" height="200" rx="50" ry="50"/></svg>'
)

const roundedCornerResizer = sharp()
    .resize(200, 200)
    .composite([
        {
            input: roundedCorners,
            blend: 'dest-in',
        },
    ])
    .png()
