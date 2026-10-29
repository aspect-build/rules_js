import fs from 'fs'
import path from 'path'

const USER_WRITE = 0o200
const PACKAGE_JSON = './node_modules/jasmine/package.json'

describe('package_store_mode = "sandbox" write isolation >', () => {
    it('keeps content and mode changes isolated from the execroot', () => {
        const runfilesLink = path.join(
            process.env.JS_BINARY__RUNFILES,
            process.env.JS_BINARY__WORKSPACE,
            'js/private/test/js_run_devserver/node_modules/jasmine/package.json'
        )
        const execrootFile = fs.realpathSync(runfilesLink)
        const originalContent = fs.readFileSync(execrootFile, 'utf-8')
        const originalMode = fs.statSync(execrootFile).mode

        // Read-only mode is not a write-isolation boundary: the devserver owns the file and can
        // chmod it before writing. This sequence would mutate the execroot through a hardlink.
        fs.chmodSync(PACKAGE_JSON, fs.statSync(PACKAGE_JSON).mode | USER_WRITE)
        fs.appendFileSync(PACKAGE_JSON, '\n')

        expect(fs.readFileSync(PACKAGE_JSON, 'utf-8')).not.toBe(originalContent)
        expect(fs.readFileSync(execrootFile, 'utf-8')).toBe(originalContent)
        expect(fs.statSync(execrootFile).mode).toBe(originalMode)
    })
})
