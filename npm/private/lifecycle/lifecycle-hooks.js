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

function normalizeBinPath(p) {
    let result = p.replace(/\\/g, '/')
    if (result.startsWith('./')) {
        result = result.substring(2)
    }
    return result
}

async function makeBins(nodeModulesPath, scope, segmentsUp) {
    const packages = await fs.promises.readdir(
        path.join(nodeModulesPath, scope)
    )
    for (package of packages) {
        if (!scope && package.startsWith('@')) {
            await makeBins(nodeModulesPath, package, segmentsUp)
            continue
        }
        const packageName = path.join(scope, package)
        const packageJsonPath = path.join(
            nodeModulesPath,
            packageName,
            'package.json'
        )
        if (fs.existsSync(packageJsonPath)) {
            let packageJsonStr = await fs.promises.readFile(packageJsonPath)
            let packageJson
            try {
                packageJson = JSON.parse(packageJsonStr)
            } catch (e) {
                // Catch and throw a more detailed error message.
                throw new Error(
                    `Error parsing ${packageName}/package.json: ${e}\n\n""""\n${packageJsonStr}\n""""`
                )
            }

            // https://docs.npmjs.com/cli/v7/configuring-npm/package-json#bin
            if (packageJson.bin) {
                await mkdirp(path.join(nodeModulesPath, '.bin'))
                let bin = packageJson.bin
                if (typeof bin == 'string') {
                    bin = { [package]: bin }
                }
                for (binName of Object.keys(bin)) {
                    binPath = normalizeBinPath(bin[binName])
                    binBash = `#!/usr/bin/env bash\nexec node "${path.join(
                        ...segmentsUp,
                        packageName,
                        binPath
                    )}" "$@"`
                    binEntryPath = path.join(nodeModulesPath, '.bin', binName)
                    await fs.promises.writeFile(binEntryPath, binBash)
                    await fs.promises.chmod(binEntryPath, '755') // executable
                }
            }
        }
    }
}

async function main(args) {
    if (args.length !== 3) {
        console.error(
            'Usage: node lifecycle-hooks.js [packageName] [packageDir] [outputDir]'
        )
        process.exit(1)
    }
    const packageName = args[0]
    const packageDir = args[1]
    const outputDir = args[2]

    await copyPackageContents(packageDir, outputDir)

    // Resolve the path to the node_modules folder for this package in the symlinked node_modules
    // tree. Output path is of the format,
    //    .../node_modules/.aspect_rules_js/package@version/node_modules/package
    //    .../node_modules/.aspect_rules_js/@scope+package@version/node_modules/@scope/package
    // Path to node_modules is one or two segments up from the output path depending on the packageName
    const segmentsUp = Array(packageName.split('/').length).fill('..')
    const nodeModulesPath = path.resolve(path.join(outputDir, ...segmentsUp))

    // Create .bin entry point files for all packages in node_modules
    await makeBins(nodeModulesPath, '', segmentsUp)

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

    const rulesJsJson = JSON.parse(
        await fs.promises.readFile(
            path.join(packageDir, 'aspect_rules_js_metadata.json')
        )
    )

    if (rulesJsJson.run_lifecycle_hooks) {
        // Runs preinstall, install, and postinstall hooks
        await runPostinstallHooks(opts)
    }

    if (rulesJsJson.scripts?.custom_postinstall) {
        // Run user specified custom postinstall hook
        await runLifecycleHook('custom_postinstall', rulesJsJson, opts)
    }
}

// Copy contents of a package dir to a destination dir (without copying the package dir itself)
async function copyPackageContents(packageDir, destDir) {
    const contents = await fs.promises.readdir(packageDir)
    await Promise.all(
        contents.map((file) =>
            copyRecursive(path.join(packageDir, file), path.join(destDir, file))
        )
    )
}

// Recursively copy files and folders
async function copyRecursive(src, dest) {
    const stats = await fs.promises.stat(src)
    if (stats.isDirectory()) {
        await mkdirp(dest)
        const contents = await fs.promises.readdir(src)
        await Promise.all(
            contents.map((file) =>
                copyRecursive(path.join(src, file), path.join(dest, file))
            )
        )
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
