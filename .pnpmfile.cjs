function readPackage(pkg, context) {
    if (pkg.name === 'mocha') {
        pkg.peerDependencies = {
            ...pkg.peerDependencies,
            'mocha-multi-reporters': '*',
        }
        context.log(
            `Adding mocha-multi-reporters@* peerDependency to ${pkg.name}@${pkg.version}`
        )
    }

    return pkg
}

module.exports = {
    hooks: {
        readPackage,
    },
}
