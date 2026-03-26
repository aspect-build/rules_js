import assert from 'node:assert'
import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __filename = import.meta.filename || fileURLToPath(import.meta.url)
const __dirname = import.meta.dirname || dirname(__filename)

describe('mocha .mjs', () => {
    it('integrates with Bazel', () => {
        assert(true)
    })

    it('is in bazel-out', () => {
        assert.match(__dirname, /bazel-out/)
    })

    it('is sandboxed', () => {
        assert.match(process.cwd(), /macro\/test(_\w+)_\/test(_\w+)\.runfiles/)
        assert.match(__dirname, /macro\/test(_\w+)_\/test(_\w+)\.runfiles/)
        assert.match(
            __filename,
            /-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/macro\/test(_\w+)_\/test(_\w+).runfiles\/_main\/macro\/test\.mjs/
        )
    })
})
