const { writeFileSync } = require('fs')

function pnpmName(name, version) {
    // Make a name/version pnpm-style name for a package name and version
    // (matches pnpm_name in js/private/pnpm_utils.bzl)
    return `${name}/${version}`
}

function parsePnpmName(pnpmName) {
    // Parse a name/version or @scope/name/version string and return
    // a [name, version] list
    const segments = pnpmName.split('/')
    if (segments.length != 2 && segments.length != 3) {
        console.error(`unexpected pnpm versioned name ${pnpmName}`)
        process.exit(1)
    }
    const version = segments.pop()
    const name = segments.join('/')
    return [name, version]
}

function gatherTransitiveClosure(
    packages,
    noOptional,
    deps,
    transitiveClosure
) {
    if (!deps) {
        return
    }
    for (const name of Object.keys(deps)) {
        const version = deps[name]
        if (!transitiveClosure[name]) {
            transitiveClosure[name] = []
        }
        if (transitiveClosure[name].includes(version)) {
            continue
        }
        transitiveClosure[name].push(version)
        const packageInfo = packages[pnpmName(name, version)]
        const dependencies = noOptional
            ? packageInfo.dependencies
            : {
                  ...packageInfo.dependencies,
                  ...packageInfo.optionalDependencies,
              }
        gatherTransitiveClosure(
            packages,
            noOptional,
            dependencies,
            transitiveClosure
        )
    }
}

async function main(argv) {
    if (argv.length !== 2) {
        console.error(
            'Usage: node translate_pnpm_lock.js [pnpmLockJson] [outputJson]'
        )
        process.exit(1)
    }
    const pnpmLockJson = argv[0]
    const outputJson = argv[1]

    const lockfile = require(pnpmLockJson)

    const lockVersion = lockfile.lockfileVersion
    if (!lockVersion) {
        console.error('unknown lockfile version')
        process.exit(1)
    }

    // TODO: support a range: lockVersion >= 5.3 and lockVersion < 6.0
    const expectedLockVersion = '5.3'
    if (lockVersion != expectedLockVersion) {
        console.error(
            `translate_pnpm_lock expected pnpm lockfile version ${expectedLockVersion}, found ${lockVersion}`
        )
        process.exit(1)
    }

    const lockPackages = lockfile.packages
    if (!lockPackages) {
        console.error('no packages in lockfile')
        process.exit(1)
    }

    const prod = !!process.env.TRANSLATE_PACKAGE_LOCK_PROD
    const dev = !!process.env.TRANSLATE_PACKAGE_LOCK_DEV
    const noOptional = !!process.env.TRANSLATE_PACKAGE_LOCK_NO_OPTIONAL

    const lockDependencies = {
        ...(!prod && lockfile.devDependencies ? lockfile.devDependencies : {}),
        ...(!dev && lockfile.dependencies ? lockfile.dependencies : {}),
        ...(!noOptional && lockfile.optionalDependencies
            ? lockfile.optionalDependencies
            : {}),
    }
    const directDependencies = []
    for (const name of Object.keys(lockDependencies)) {
        directDependencies.push(pnpmName(name, lockDependencies[name]))
    }

    packages = {}
    for (const packagePath of Object.keys(lockPackages)) {
        const packageSnapshot = lockPackages[packagePath]
        if (!packagePath.startsWith('/')) {
            console.error(`unsupported package path ${packagePath}`)
            process.exit(1)
        }
        const package = packagePath.slice(1)
        const [name, pnpmVersion] = parsePnpmName(package)
        const resolution = packageSnapshot.resolution
        if (!resolution) {
            console.error(`package ${packagePath} has no resolution field`)
            process.exit(1)
        }
        const integrity = resolution.integrity
        if (!integrity) {
            console.error(`package ${packagePath} has no integrity field`)
            process.exit(1)
        }
        const dev = !!packageSnapshot.dev
        const optional = !!packageSnapshot.optional
        const hasBin = !!packageSnapshot.hasBin
        const requiresBuild = !!packageSnapshot.requiresBuild
        const dependencies = packageSnapshot.dependencies || {}
        const optionalDependencies = packageSnapshot.optionalDependencies || {}
        packages[package] = {
            name,
            pnpmVersion,
            integrity,
            dependencies,
            optionalDependencies,
            dev,
            optional,
            hasBin,
            requiresBuild,
        }
    }

    for (const package of Object.keys(packages)) {
        const packageInfo = packages[package]
        const transitiveClosure = {}
        transitiveClosure[packageInfo.name] = [packageInfo.pnpmVersion]
        const dependencies = noOptional
            ? packageInfo.dependencies
            : {
                  ...packageInfo.dependencies,
                  ...packageInfo.optionalDependencies,
              }
        gatherTransitiveClosure(
            packages,
            noOptional,
            dependencies,
            transitiveClosure
        )
        packageInfo.transitiveClosure = transitiveClosure
    }

    result = { dependencies: directDependencies, packages }

    writeFileSync(outputJson, JSON.stringify(result, null, 2))
}

;(async () => {
    await main(process.argv.slice(2))
})()
