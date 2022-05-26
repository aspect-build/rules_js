const patchfs = require('./fs').patcher
const { JS_BINARY__FS_PATH_ROOTS } = process.env

if (JS_BINARY__FS_PATH_ROOTS) {
    const fs = require('fs')
    patchfs(fs, JS_BINARY__FS_PATH_ROOTS.split(':'))
}
