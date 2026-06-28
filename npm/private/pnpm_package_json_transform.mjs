import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, isAbsolute } from 'node:path'

function resolvePath(p) {
  if (isAbsolute(p)) return p
  const execroot = process.env.JS_BINARY__EXECROOT
  if (execroot) return resolve(execroot, p)
  return resolve(p)
}

const args = process.argv.slice(2)
let catalogsJsonArg, packageJsonArg, outputArg, versionArg
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--catalogs-json') catalogsJsonArg = args[++i]
  else if (args[i] === '--package-json') packageJsonArg = args[++i]
  else if (args[i] === '--output') outputArg = args[++i]
  else if (args[i] === '--version') versionArg = args[++i]
}

if (!catalogsJsonArg || !packageJsonArg || !outputArg) {
  process.stderr.write(
    'usage: pnpm_package_json_transform --catalogs-json <path> --package-json <path> --output <path> [--version <ver>]\n'
  )
  process.exit(1)
}

const catalogs = JSON.parse(readFileSync(resolvePath(catalogsJsonArg), 'utf8'))
const manifest = JSON.parse(readFileSync(resolvePath(packageJsonArg), 'utf8'))

if (versionArg) manifest.version = versionArg

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
    if (rest === '*' || rest === '^' || rest === '~') return version
    return rest
  }
  return version
}

const depFields = ['dependencies', 'peerDependencies', 'optionalDependencies']
for (const field of depFields) {
  const deps = manifest[field]
  if (deps && typeof deps === 'object') {
    const sorted = {}
    for (const key of Object.keys(deps).sort()) {
      sorted[key] = resolveVersion(key, deps[key])
    }
    manifest[field] = sorted
  }
}

delete manifest.devDependencies

// Apply publishConfig overrides (pnpm promotes these to top-level on publish)
const pc = manifest.publishConfig
if (pc && typeof pc === 'object') {
  for (const field of ['main', 'types', 'typings', 'module', 'exports', 'bin', 'browser', 'typesVersions']) {
    if (field in pc) manifest[field] = pc[field]
  }
}

writeFileSync(resolvePath(outputArg), JSON.stringify(manifest, null, 2) + '\n')
