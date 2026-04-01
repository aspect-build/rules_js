const assert = require('assert')
const { dirname } = require('node:path')

describe('mocha .cjs', () => {
    it('integrates with Bazel', () => {
        assert(true)
    })

    it('is in bazel-out', () => {
        assert.match(__dirname, /bazel-out/)
    })

    it('is sandboxed', () => {
        assert.match(
            process.cwd(),
            /examples\/macro\/test(_\w+)_\/test(_\w+)\.runfiles/
        )
        assert.match(
            __dirname,
            /examples\/macro\/test(_\w+)_\/test(_\w+)\.runfiles/
        )
        assert.match(
            __filename,
            /-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/examples\/macro\/test(_\w+)_\/test(_\w+).runfiles\/_main\/examples\/macro\/test\.cjs/
        )
        assert.equal(__dirname, dirname(__filename))
    })
})
