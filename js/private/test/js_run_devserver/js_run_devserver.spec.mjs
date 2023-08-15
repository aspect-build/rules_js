import fs from 'fs'

describe('node_modules symlinks >', () => {
    const execRootDir = process.env.JS_BINARY__EXECROOT
    const runfilesDir = process.env.JS_BINARY__RUNFILES

    beforeAll(() => {
        // first ensure that the environment variables are strings with some value
        if (typeof execRootDir !== 'string' || execRootDir.length === 0) {
            throw new Error(`process.env.JS_BINARY__EXECROOT is empty - can't run tests which rely on it`)
        }
        if (typeof runfilesDir !== 'string' || runfilesDir.length === 0) {
            throw new Error(`process.env.JS_BINARY__RUNFILES is empty - can't run tests which rely on it`)
        }
    })

    it(`symlinks non-scoped node_modules (e.g. 'jasmine') to the exec root instead of runfiles to ensure bundlers see a single node_modules tree (https://github.com/aspect-build/rules_js/pull/1043)`, () => {
        const reactSymlink = fs.readlinkSync('./node_modules/jasmine')

        expect(reactSymlink).toContain(execRootDir)
        expect(reactSymlink).not.toContain(runfilesDir)
    })

    it(`symlinks scoped node_modules (e.g. '@types/node') to the exec root instead of runfiles to ensure bundlers see a single node_modules tree (https://github.com/aspect-build/rules_js/issues/1204)`, () => {
        const testComponentSymlink = fs.readlinkSync('./node_modules/@types/node')

        expect(testComponentSymlink).toContain(execRootDir)
        expect(testComponentSymlink).not.toContain(runfilesDir)
    })
})
