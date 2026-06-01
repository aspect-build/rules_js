import { spawnSync } from 'node:child_process'
import {
    copyFileSync,
    existsSync,
    mkdtempSync,
    rmSync,
} from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'

const [toolPath, packageDir, ...restArgs] = process.argv.slice(2)

if (!toolPath || !packageDir) {
    console.error(
        'Expected publish tool path and package directory arguments.',
    )
    process.exit(1)
}

const packagePath = path.resolve(packageDir)

let cleanupCwd
let spawnOptions = {
    stdio: 'inherit',
}

if (process.env.BUILD_WORKSPACE_DIRECTORY) {
    cleanupCwd = mkdtempSync(path.join(tmpdir(), 'rules-js-pnpm-publish-'))

    // Give pnpm only the workspace-level files it needs for publish settings.
    for (const filename of ['pnpm-workspace.yaml', '.npmrc']) {
        const source = path.join(process.env.BUILD_WORKSPACE_DIRECTORY, filename)
        if (existsSync(source)) {
            copyFileSync(source, path.join(cleanupCwd, filename))
        }
    }

    spawnOptions = {
        cwd: cleanupCwd,
        env: {
            ...process.env,
            // The pnpm binary is itself a js_binary launcher; this keeps it runnable after
            // changing cwd away from the Bazel output tree.
            BAZEL_BINDIR: process.env.BAZEL_BINDIR || '.',
        },
        stdio: 'inherit',
    }
}

const spawn = spawnSync(
    path.resolve(toolPath),
    ['publish', packagePath, '--no-git-checks', ...restArgs],
    spawnOptions,
)

if (cleanupCwd) {
    rmSync(cleanupCwd, {
        force: true,
        recursive: true,
    })
}

if (spawn.error) {
    console.error(spawn.error.message)
    process.exit(1)
}

if (spawn.signal) {
    console.error(`pnpm publish exited with signal ${spawn.signal}`)
    process.exit(1)
}

process.exit(spawn.status)
