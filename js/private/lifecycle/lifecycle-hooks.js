const {
    mkdirSync,
    copyFileSync,
    readdirSync,
    readFileSync,
    existsSync,
    statSync,
} = require('fs')
const path = require('path')
const { runPostinstallHooks } = require('@pnpm/lifecycle')
const runLifecycleHook = require('@pnpm/lifecycle').default

async function main(argv) {
    if (argv.length !== 2) {
        console.error('Usage: node lifecycle-hooks.js [packageDir] [outputDir]')
        process.exit(1)
    }
    const packageDir = argv[0]
    const outputDir = argv[1]

    copyPackageContents(packageDir, outputDir)

    const packageJson = JSON.parse(
        readFileSync(path.join(packageDir, 'package.json'))
    )

    if (
        packageJson.scripts?.preinstall ||
        packageJson.scripts?.install ||
        packageJson.scripts?.postinstall ||
        packageJson.scripts?._rules_js_postinstall
    ) {
        // node_modules folder that the node_package dependency targets which are in the same bazel package output
        const nodeModulesPath = path.resolve(
            path.join(outputDir, '..', 'node_modules')
        )

        // If the package we're running postinstall on has no deps, then node_modules
        // won't exist in the sandbox. The lifecycle functions provided by pnpm require
        // it to exist, so create an empty folder if needed.
        if (!existsSync(nodeModulesPath)) {
            mkdirSync(nodeModulesPath)
        }

        const opts = {
            pkgRoot: path.resolve(outputDir),
            rawConfig: {
                stdio: 'inherit',
            },
            rootModulesDir: nodeModulesPath,
            unsafePerm: true, // Don't run under a specific user/group
        }

        // Runs preinstall, install, and postinstall hooks
        await runPostinstallHooks(opts)

        if (packageJson.scripts?._rules_js_postinstall) {
            await runLifecycleHook('_rules_js_postinstall', packageJson, opts)
        }
    }
}

// Copy contents of a package dir to a destination dir (without copying the package dir itself)
function copyPackageContents(packageDir, destDir) {
    readdirSync(packageDir).forEach((file) => {
        copyRecursiveSync(path.join(packageDir, file), path.join(destDir, file))
    })
}

// Recursively copy files and folders
function copyRecursiveSync(src, dest) {
    const stats = statSync(src)
    if (stats.isDirectory()) {
        mkdirSync(dest)
        readdirSync(src).forEach(function (fileName) {
            copyRecursiveSync(
                path.join(src, fileName),
                path.join(dest, fileName)
            )
        })
    } else {
        copyFileSync(src, dest)
    }
}

;(async () => {
    await main(process.argv.slice(2))
})()
