import { join, dirname } from 'node:path'
import { rmSync, existsSync } from 'node:fs'

const bazelPackage = process.env['BAZEL_PACKAGE']
if (!process.cwd().endsWith(bazelPackage)) {
    throw new Error('This script must be run from Next.js app root')
}

let nextjsStandaloneConfig = process.env['NEXTJS_STANDALONE_CONFIG']
if (nextjsStandaloneConfig.startsWith(process.env.BAZEL_BINDIR)) {
    nextjsStandaloneConfig = nextjsStandaloneConfig.slice(
        process.env.BAZEL_BINDIR.length + 1
    )
}

// Support invocation from another workspace: strip "external/<repo>/" if present
nextjsStandaloneConfig = nextjsStandaloneConfig.replace(/^external\/[^/]+\//, '')

if (!nextjsStandaloneConfig.startsWith(bazelPackage)) {
    throw new Error(
        `Next.js config must be relative to the app root: ${nextjsStandaloneConfig}`
    )
}

const NEXTJS_OUTDIR = '.next'

log(`Wrapping config: ${nextjsStandaloneConfig}`)
log(`Output dir: ${NEXTJS_OUTDIR}`)

/**
 * NextJs within bazel copies node_modules symlinks pointing into .aspect_rules_js within the sandbox.
 * Clear all `standalone/node_modules` and assume the bazel rule will include the necessary npm packages.
 */
function nextjsFixSymlinks() {
    for (let p = process.env['BAZEL_PACKAGE']; ; p = dirname(p)) {
        const d = join(NEXTJS_OUTDIR, 'standalone', p, 'node_modules')
        if (existsSync(d)) {
            log(`Removing ${d}`)

            try {
                rmSync(join(NEXTJS_OUTDIR, 'standalone', p, 'node_modules'), {
                    recursive: true,
                    force: true,
                })
            } catch (e) {
                // node_modules won't exist at every level, and multiple nextjs node processes
                // might all be trying to remove it at the same time.
            }
        }

        if (p === '' || p === '.') {
            break
        }
    }
}

function log(...args) {
    console.log(`[NextJs Bazel (${process.pid})]: `, ...args)
}

// Run the symlinks fixes on exit.
process.on('exit', nextjsFixSymlinks)

const nextjsStandaloneConfigRel = nextjsStandaloneConfig.slice(
    bazelPackage.length + 1
)
const c = await import(`./${nextjsStandaloneConfigRel}`)
export default c.default || c
