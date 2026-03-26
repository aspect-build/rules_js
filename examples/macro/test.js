const assert = require('assert')
const { dirname } = require('node:path')

describe('mocha .js', () => {
    it('integrates with Bazel', () => {
        assert(true)
    })

    it('is in bazel-out', () => {
        assert.match(__dirname, /bazel-out/)
    })

    it('is sandboxed', () => {
        assert.match(
            process.cwd(),
            /macro\/test(_\w+)?_\/test(_\w+)?\.runfiles/
        )
        assert.match(__dirname, /macro\/test(_\w+)?_\/test(_\w+)?\.runfiles/)
        assert.match(
            __filename,
            /-sandbox\/\d+\/execroot\/_main\/bazel-out\/[^/]+\/bin\/macro\/test(_\w+)?_\/test(_\w+)?\.runfiles\/_main\/macro\/test\.js/
        )
        assert.equal(__dirname, dirname(__filename))
    })
})
