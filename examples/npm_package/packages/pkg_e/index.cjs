const {
    getAcornVersion,
    toAst,
    uuid,
    sandboxAssert: dSandboxAssert,
} = require('@mycorp/pkg-d')

const { sandboxAssert: bSandboxAssert } = require('@mycorp/pkg-b')

function sandboxAssert() {
    if (!/-sandbox\/\d+\/execroot\//.test(__filename)) {
        throw new Error(`Not in sandbox: ${__filename}`)
    }

    // Files are in the runfiles directory via js_library(srcs) instead
    // of copies in the npm package store.
    if (!__filename.startsWith(process.env.RUNFILES_DIR)) {
        throw new Error(`Not runfiles: ${__filename}`)
    }

    bSandboxAssert()
    dSandboxAssert()
    require('@mycorp/pkg-b').sandboxAssert()
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

global['pkg_e__cjs'] ??= 0
if (++global['pkg_e__cjs'] > 1) {
    throw new Error('pkg_e index.cjs loaded multiple times')
}
sandboxAssert()

module.exports = {
    getAcornVersion,
    sandboxAssert,
    toAst,
    uuid,
}
