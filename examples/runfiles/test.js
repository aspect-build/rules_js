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
        const testFixturePath = runfiles.resolve(
            'aspect_rules_js/examples/runfiles/test_fixture.md'
        )
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve with forward slashes', () => {
        const testFixturePath = runfiles.resolve(
            'aspect_rules_js\\examples\\runfiles\\test_fixture.md'
        )
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve with the __main__ module alias', () => {
        const testFixturePath = runfiles.resolve(
            '__main__/examples/runfiles/test_fixture.md'
        )
        const expectedPath = join(__dirname, 'test_fixture.md')

        assert(
            normalizePath(testFixturePath) == normalizePath(expectedPath),
            `Expected the test fixture to be resolved next to the spec source file: ${testFixturePath} vs ${expectedPath}`
        )
    })

    it('should properly resolve a subdirectory of a runfile', () => {
        const packagePath = runfiles.resolve('aspect_rules_js/examples')
        // Alternate with trailing slash
        const packagePath2 = runfiles.resolve('aspect_rules_js/examples/')
        const expectedPath = dirname(
            dirname(
                runfiles.resolve(
                    'aspect_rules_js/examples/runfiles/test_fixture.md.generated_file_suffix'
                )
            )
        )

        assert(
            normalizePath(packagePath) == normalizePath(expectedPath),
            `Expected to resolve a subdirectory of a runfile: ${packagePath} vs ${expectedPath}`
        )
        assert(
            normalizePath(packagePath2) == normalizePath(expectedPath),
            `Expected to resolve a subdirectory of a runfile: ${packagePath2} vs ${expectedPath}`
        )
    })

    it('should properly resolve the workspace root of a runfile', () => {
        const packagePath = runfiles.resolve('aspect_rules_js')
        // Alternate with trailing slash
        const packagePath2 = runfiles.resolve('aspect_rules_js/')
        const expectedPath = dirname(
            dirname(
                dirname(
                    runfiles.resolve(
                        'aspect_rules_js/examples/runfiles/test_fixture.md.generated_file_suffix'
                    )
                )
            )
        )

        assert(
            normalizePath(packagePath) == normalizePath(expectedPath),
            `Expected to resolve the workspace root of a runfile: ${packagePath} vs ${expectedPath}`
        )
        assert(
            normalizePath(packagePath2) == normalizePath(expectedPath),
            `Expected to resolve the workspace root of a runfile: ${packagePath2} vs ${expectedPath}`
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
