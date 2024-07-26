import packageJson from './package.json' assert { type: 'json' }
import * as assert from 'uvu/assert'
import * as lib from '@e2e/lib'
assert.is(2 + 2, 4)
export const id = () =>
    `${packageJson.name}@${
        packageJson.version ? packageJson.version : '0.0.0'
    }` + lib.id()
