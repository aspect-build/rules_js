const assert = require('assert')

describe('mocha', () => {
    it('integrates with Bazel', () => {
        assert(true)
    })

    it('is sandboxed', () => {
        assert.match(__dirname, /examples\/macro\/test\.sh\.runfiles/)
    })
})
