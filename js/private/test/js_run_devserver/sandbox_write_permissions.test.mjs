import fs from 'fs'
import path from 'path'

const USER_WRITE = 0o200

// The package store file that both the sandbox and the execroot hold a copy of.
const PACKAGE_JSON = './node_modules/jasmine/package.json'

describe('package_store_mode = "sandbox" with grant_sandbox_write_permissions >', () => {
    it('grants write permissions on the sandbox copy', () => {
        const mode = fs.statSync(PACKAGE_JSON).mode

        expect(mode & USER_WRITE).toBe(USER_WRITE)
    })

    it('does not mutate the permissions of the file in the execroot', () => {
        // The runfiles tree still points at the read-only Bazel outputs; sandbox chmod must not
        // affect them.
        const runfilesLink = path.join(
            process.env.JS_BINARY__RUNFILES,
            process.env.JS_BINARY__WORKSPACE,
            'js/private/test/js_run_devserver/node_modules/jasmine/package.json'
        )
        const execrootFile = fs.realpathSync(runfilesLink)

        expect(execrootFile).toContain(process.env.JS_BINARY__EXECROOT)
        expect(fs.statSync(execrootFile).mode & USER_WRITE).toBe(0)
    })
})
