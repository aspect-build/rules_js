import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, isAbsolute } from 'node:path'
import { parseArgs } from 'node:util'

function resolvePath(p) {
  if (isAbsolute(p)) return p
  const execroot = process.env.JS_BINARY__EXECROOT
  if (execroot) return resolve(execroot, p)
  return resolve(p)
}

const { values: argv } = parseArgs({
  options: {
    'catalogs-json': { type: 'string' },
    'package-json': { type: 'string' },
    'output': { type: 'string' },
    'version': { type: 'string' },
    'workspace-version': { type: 'string', multiple: true },
  },
  strict: true,
})

if (!argv['catalogs-json'] || !argv['package-json'] || !argv['output']) {
  process.stderr.write(
    'usage: pnpm_package_json_transform --catalogs-json <path> --package-json <path> --output <path> [--version <ver>] [--workspace-version name=ver]...\n'
  )
  process.exit(1)
}

const catalogs = JSON.parse(readFileSync(resolvePath(argv['catalogs-json']), 'utf8'))
const manifest = JSON.parse(readFileSync(resolvePath(argv['package-json']), 'utf8'))

const workspaceVersions = {}
for (const entry of argv['workspace-version'] ?? []) {
  const eq = entry.indexOf('=')
  workspaceVersions[entry.slice(0, eq)] = entry.slice(eq + 1)
}

if (argv.version) manifest.version = argv.version

// --- Dependency protocol resolution ---

function resolveVersion(pkgName, version) {
  if (version.startsWith('catalog:')) {
    const catalogName = version.slice('catalog:'.length) || 'default'
    const catalog = catalogs[catalogName]
    if (!catalog) throw new Error(`Unknown catalog '${catalogName}' referenced by '${pkgName}'`)
    const resolved = catalog[pkgName]
    if (!resolved) throw new Error(`Package '${pkgName}' not found in catalog '${catalogName}'`)
    return resolved
  }
  if (version.startsWith('workspace:')) {
    const rest = version.slice('workspace:'.length)
    if (rest === '*' || rest === '^' || rest === '~') {
      const resolved = workspaceVersions[pkgName]
      if (!resolved) throw new Error(`Workspace package '${pkgName}' not found in srcs dependencies.`)
      if (rest === '*') return resolved
      return rest + resolved
    }
    return rest
  }
  return version
}

for (const field of ['dependencies', 'peerDependencies', 'optionalDependencies']) {
  const deps = manifest[field]
  if (deps && typeof deps === 'object') {
    const sorted = {}
    for (const key of Object.keys(deps).sort()) {
      sorted[key] = resolveVersion(key, deps[key])
    }
    manifest[field] = sorted
  }
}

// --- Strip devDependencies ---

delete manifest.devDependencies

// --- Strip publish lifecycle scripts ---

const PUBLISH_LIFECYCLE_SCRIPTS = new Set([
  'prepublishOnly', 'prepack', 'prepare', 'postpack',
  'publish', 'postpublish',
])

if (manifest.scripts) {
  for (const name of PUBLISH_LIFECYCLE_SCRIPTS) {
    delete manifest.scripts[name]
  }
  if (Object.keys(manifest.scripts).length === 0) {
    delete manifest.scripts
  }
}

// --- Strip pnpm-specific fields ---

delete manifest.pnpm
delete manifest.packageManager

// --- publishConfig promotion ---

const PUBLISH_CONFIG_PROMOTABLE = new Set([
  'main', 'module', 'types', 'typings', 'exports', 'browser',
  'esnext', 'es2015', 'unpkg', 'umd:main',
  'bin', 'engines', 'type', 'os', 'cpu', 'libc',
  'typesVersions', 'imports',
])

if (manifest.publishConfig && typeof manifest.publishConfig === 'object') {
  for (const field of PUBLISH_CONFIG_PROMOTABLE) {
    if (field in manifest.publishConfig) {
      manifest[field] = manifest.publishConfig[field]
      delete manifest.publishConfig[field]
    }
  }
  if (Object.keys(manifest.publishConfig).length === 0) {
    delete manifest.publishConfig
  }
}

// --- Normalize bin (string → object) ---

if (typeof manifest.bin === 'string') {
  let binName = manifest.name || ''
  const slashIdx = binName.indexOf('/')
  if (slashIdx !== -1) binName = binName.slice(slashIdx + 1)
  manifest.bin = { [binName]: manifest.bin }
}

// --- Normalize repository (string → object) ---

if (typeof manifest.repository === 'string') {
  manifest.repository = { type: 'git', url: manifest.repository }
}

writeFileSync(resolvePath(argv.output), JSON.stringify(manifest, null, 2) + '\n')
