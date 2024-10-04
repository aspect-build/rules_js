const { join, dirname } = require('path')
const { Runfiles } = require('@bazel/runfiles')

function describe(name, fn) {
    console.log(name)
    fn()
}
function it(name, fn) {
    console.log(`  ${name}`)
    fn()
}

function assert(t, msg) {
    if (!t) {
        throw new Error(msg)
    }
}

const runfiles = new Runfiles(process.env)

describe('runfile resolution', () => {
    it('should properly resolve the files with the module(name)', () => {
        const testFixturePath = runfiles.resolve('e2e_runfiles/test_fixture.md')
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve with forward slashes', () => {
        const testFixturePath = runfiles.resolve(
            'e2e_runfiles\\test_fixture.md'
        )
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve with the __main__ module alias', () => {
        const testFixturePath = runfiles.resolve('__main__/test_fixture.md')
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve a runfile within a direct module dependency', () => {
        const fsPatchPath = runfiles.resolve(
            'aspect_rules_js/js/private/node-patches/fs.cjs'
        )

        assert(!!fsPatchPath, `Expected to find fs patches`)
        assert(
            fsPatchPath.indexOf('/aspect_rules_js/') == -1,
            `Expected to find fs patches in a resolved bzlmod directory`
        )
    })
})

/**
 * Normalizes the delimiters within the specified path. This is useful for test assertions
 * where paths might be computed using different path delimiters.
 */
function normalizePath(value) {
    return value.replace(/\\/g, '/')
}
