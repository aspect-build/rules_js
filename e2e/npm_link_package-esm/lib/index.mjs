import packageJson from './package.json'
import * as assert from 'uvu/assert'
assert.is(2 + 2, 4)
export const id = () =>
    `${packageJson.name}@${packageJson.version ? packageJson.version : '0.0.0'}`
