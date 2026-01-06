const {
    getAcornVersion,
    toAst,
    uuid,
    sandboxAssert: dSandboxAssert,
} = require('@mycorp/pkg-d')

function sandboxAssert() {
    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }

    dSandboxAssert()
    require('@mycorp/pkg-d').sandboxAssert()

    // Resolve of pkg-d
    const pkgDPath = require.resolve('@mycorp/pkg-d')
    if (!/-sandbox\/\d+\/execroot\//.test(pkgDPath)) {
        throw new Error(`pkg-d not in sandbox: ${pkgDPath}`)
    }
    if (!pkgDPath.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`pkg-d not in runfiles: ${pkgDPath}`)
    }
}

sandboxAssert()

module.exports = {
    getAcornVersion,
    sandboxAssert,
    toAst,
    uuid,
}
