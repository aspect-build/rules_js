import { execFileSync } from 'node:child_process'
import path from 'node:path'

// js_binary patches node's fs module so that resolving a symlink never appears to leave the
// runfiles/execroot roots. That patch would hide exactly the escape these tests are looking for, so
// every path resolution here happens in a plain node process without the patches applied — which is
// also what a non-node bundler such as Turbopack does when it calls realpath(3).
function unpatchedNode(script, arg) {
    return execFileSync(process.execPath, ['-e', script, arg], {
        encoding: 'utf-8',
    })
}

export function realpath(p) {
    return unpatchedNode(
        'process.stdout.write(require("fs").realpathSync(process.argv[1]))',
        path.resolve(p)
    )
}

// Walks the sandbox and returns every symlink whose target resolves outside of it.
export function findEscapingSymlinks(sandboxRoot, startDir) {
    const script = `
        const fs = require('fs')
        const path = require('path')
        const root = process.argv[1].split(path.delimiter)[0]
        const start = process.argv[1].split(path.delimiter)[1]
        const escaping = []
        const inside = (p) => {
            const rel = path.relative(root, p)
            return !!rel && rel !== '..' && !rel.startsWith('..' + path.sep)
        }
        const walk = (dir) => {
            for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
                const p = path.join(dir, entry.name)
                if (entry.isSymbolicLink()) {
                    let real
                    try {
                        real = fs.realpathSync(p)
                    } catch {
                        continue // broken link, not an escape
                    }
                    if (!inside(real)) {
                        escaping.push(path.relative(root, p) + ' -> ' + real)
                    }
                } else if (entry.isDirectory()) {
                    walk(p)
                }
            }
        }
        walk(start)
        process.stdout.write(JSON.stringify(escaping))
    `
    return JSON.parse(
        unpatchedNode(
            script,
            [sandboxRoot, path.resolve(startDir)].join(path.delimiter)
        )
    )
}

// Walks up from the working directory to the sandbox root that js_run_devserver created.
export function findSandboxRoot() {
    let dir = process.cwd()
    while (true) {
        if (path.basename(dir).startsWith('js_run_devserver-')) {
            return dir
        }
        const parent = path.dirname(dir)
        if (parent === dir) {
            throw new Error(
                `Could not find the js_run_devserver sandbox root above ${process.cwd()}`
            )
        }
        dir = parent
    }
}

export function isInside(root, p) {
    const rel = path.relative(root, p)
    return !!rel && rel !== '..' && !rel.startsWith('..' + path.sep)
}
