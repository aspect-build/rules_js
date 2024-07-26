console.log(process.argv)
import a from '@aspect-test/a/index.js'
console.log('--a--')
console.log(a.id())
console.log(a.idB())
console.log(a.idC())
import b from '@aspect-test/b/index.js'
console.log('--b--')
console.log(b.id())
console.log(b.idA())
console.log(b.idC())
import c from '@aspect-test/c/index.js'
console.log('--c--')
console.log(c.id())
import * as fp from '@e2e/lib'
console.log('--@e2e/lib--')
console.log(fp.id())
import * as fpp from '@e2e/pkg'
console.log('--@e2e/pkg--')
console.log(fpp.id())
import * as wrapper from '@e2e/wrapper-lib'
console.log('--@e2e/wrapper-lib--')
console.log(wrapper.id())
console.log(wrapper.libId())
console.log(wrapper.subdirId())
console.log(wrapper.pkgId())
import rulesFooA from '../../foo/node_modules/@aspect-test/a/index.js'
console.log('--rulesFooA--')
console.log(rulesFooA.id())
console.log(rulesFooA.idB())
console.log(rulesFooA.idC())
import sharp from 'sharp'
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
