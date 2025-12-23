const assert = require('assert')
const { dirname } = require('node:path')

describe('mocha', () => {
    it('integrates with Bazel', () => {
        assert(true)
    })

    it('is in bazel-out', () => {
        assert.match(__dirname, /bazel-out/)
    })

    it('is sandboxed', () => {
        assert.match(__dirname, /examples\/macro\/test_\/test\.runfiles/)
        assert.match(
            __filename,
            /-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/examples\/macro\/test_\/test.runfiles\/_main\/examples\/macro\/test\.js/
        )
        assert.equal(__dirname, dirname(__filename))
    })
})
