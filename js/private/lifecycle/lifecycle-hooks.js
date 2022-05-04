const fs = require('fs')
const path = require('path')
const { runPostinstallHooks } = require('@pnpm/lifecycle')
const runLifecycleHook = require('@pnpm/lifecycle').default

async function mkdirp(p) {
    if (p && !fs.existsSync(p)) {
        await mkdirp(path.dirname(p))
        await fs.promises.mkdir(p)
    }
}

async function main(args) {
    if (args.length !== 2) {
        console.error('Usage: node lifecycle-hooks.js [packageDir] [outputDir]')
        process.exit(1)
    }
    const packageDir = args[0]
    const outputDir = args[1]

    await copyPackageContents(packageDir, outputDir)

    const packageJson = JSON.parse(
        await fs.promises.readFile(path.join(packageDir, 'package.json'))
    )

    // root of node_modules folder for this package is up one level from the outputDir in the
    // symlinked node_modules structure
    const nodeModulesPath = path.resolve(path.join(outputDir, '..'))

    // export interface RunLifecycleHookOptions {
    //     args?: string[];
    //     depPath: string;
    //     extraBinPaths?: string[];
    //     extraEnv?: Record<string, string>;
    //     initCwd?: string;
    //     optional?: boolean;
    //     pkgRoot: string;
    //     rawConfig: object;
    //     rootModulesDir: string;
    //     scriptShell?: string;
    //     silent?: boolean;
    //     scriptsPrependNodePath?: boolean | 'warn-only';
    //     shellEmulator?: boolean;
    //     stdio?: string;
    //     unsafePerm: boolean;
    // }
    const opts = {
        pkgRoot: path.resolve(outputDir),
        rawConfig: {
            stdio: 'inherit',
        },
        silent: false,
        stdio: 'inherit',
        rootModulesDir: nodeModulesPath,
        unsafePerm: true, // Don't run under a specific user/group
    }

    if (packageJson.scripts?._rules_js_run_lifecycle_hooks) {
        // Runs preinstall, install, and postinstall hooks
        await runPostinstallHooks(opts)
    }

    if (packageJson.scripts?._rules_js_custom_postinstall) {
        // Run user specified custom postinstall hook
        await runLifecycleHook(
            '_rules_js_custom_postinstall',
            packageJson,
            opts
        )
    }
}

// Copy contents of a package dir to a destination dir (without copying the package dir itself)
async function copyPackageContents(packageDir, destDir) {
    const contents = await fs.promises.readdir(packageDir)
    contents.forEach(async (file) => {
        await copyRecursive(
            path.join(packageDir, file),
            path.join(destDir, file)
        )
    })
}

// Recursively copy files and folders
async function copyRecursive(src, dest) {
    const stats = await fs.promises.stat(src)
    if (stats.isDirectory()) {
        await mkdirp(dest)
        const contents = await fs.promises.readdir(src)
        contents.forEach(async (fileName) => {
            await copyRecursive(
                path.join(src, fileName),
                path.join(dest, fileName)
            )
        })
    } else {
        await fs.promises.copyFile(src, dest)
    }
}

;(async () => {
    try {
        await main(process.argv.slice(2))
    } catch (e) {
        console.error(e)
        process.exit(1)
    }
})()
