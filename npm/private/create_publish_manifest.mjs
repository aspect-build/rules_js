import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import path from 'node:path'

// Fields that pnpm promotes from publishConfig to the top level.
// Superset across pnpm 9/10/11.
const PUBLISH_CONFIG_WHITELIST = new Set([
    'bin',
    'browser',
    'cpu',
    'engines',
    'es2015',
    'esnext',
    'exports',
    'imports',
    'libc',
    'main',
    'module',
    'os',
    'type',
    'types',
    'typings',
    'typesVersions',
    'umd:main',
    'unpkg',
])

const PUBLISH_LIFECYCLE_SCRIPTS = new Set([
    'prepublish',
    'prepare',
    'prepublishOnly',
    'postpublish',
])

function parseCatalogProtocol(specifier) {
    if (typeof specifier !== 'string' || !specifier.startsWith('catalog:')) {
        return null
    }
    const name = specifier.slice('catalog:'.length).trim()
    return name === '' ? 'default' : name
}

function resolveCatalogSpecifier(catalogs, packageName, specifier) {
    const catalogName = parseCatalogProtocol(specifier)
    if (catalogName === null) return specifier

    const catalog = catalogs[catalogName]
    if (!catalog || !(packageName in catalog)) {
        throw new Error(
            `No entry for '${packageName}' in catalog '${catalogName}'`
        )
    }

    const resolved = catalog[packageName]
    if (parseCatalogProtocol(resolved) !== null) {
        throw new Error(
            `Recursive catalog: reference for '${packageName}' in catalog '${catalogName}'`
        )
    }
    for (const protocol of ['workspace:', 'link:', 'file:']) {
        if (typeof resolved === 'string' && resolved.startsWith(protocol)) {
            throw new Error(
                `Unsupported protocol '${protocol}' in catalog value for '${packageName}'`
            )
        }
    }
    return resolved
}

function resolveCatalogs(manifest, catalogs) {
    for (const field of [
        'dependencies',
        'devDependencies',
        'optionalDependencies',
        'peerDependencies',
    ]) {
        const deps = manifest[field]
        if (!deps) continue
        for (const [name, specifier] of Object.entries(deps)) {
            deps[name] = resolveCatalogSpecifier(catalogs, name, specifier)
        }
    }
}

function applyPublishConfig(manifest) {
    const { publishConfig } = manifest
    if (!publishConfig) return

    for (const key of Object.keys(publishConfig)) {
        if (PUBLISH_CONFIG_WHITELIST.has(key)) {
            manifest[key] = publishConfig[key]
            delete publishConfig[key]
        }
    }
    if (Object.keys(publishConfig).length === 0) {
        delete manifest.publishConfig
    }
}

function stripPnpmFields(manifest) {
    delete manifest.pnpm
    delete manifest.packageManager

    if (manifest.scripts) {
        for (const name of PUBLISH_LIFECYCLE_SCRIPTS) {
            delete manifest.scripts[name]
        }
        if (Object.keys(manifest.scripts).length === 0) {
            delete manifest.scripts
        }
    }
}

// Parse the catalog/catalogs sections from pnpm-workspace.yaml.
// Handles the subset of YAML used by these sections: flat maps of
// unquoted or quoted string key-value pairs, optionally nested one
// level deep for named catalogs.
function parseCatalogsFromWorkspaceYaml(content) {
    const catalogs = {}
    const lines = content.split('\n')

    let section = null
    let currentCatalogName = null

    for (const raw of lines) {
        if (/^\s*(#|$)/.test(raw)) continue

        const indent = raw.match(/^(\s*)/)[1].length

        if (indent === 0) {
            const m = raw.match(/^(catalog|catalogs)\s*:/)
            section = m ? m[1] : null
            currentCatalogName = null
            if (section === 'catalog') {
                currentCatalogName = 'default'
                if (!catalogs.default) catalogs.default = {}
            }
            continue
        }

        if (!section) continue

        const stripped = raw.trim()
        const kvMatch = stripped.match(
            /^['"]?([^'":\s][^'":]*?)['"]?\s*:\s*['"]?(.*?)['"]?\s*$/
        )
        if (!kvMatch) continue

        const [, key, value] = kvMatch

        if (section === 'catalog') {
            catalogs.default[key] = value
        } else if (section === 'catalogs') {
            if (indent <= 4 && !value) {
                currentCatalogName = key
                if (!catalogs[key]) catalogs[key] = {}
            } else if (currentCatalogName && value) {
                catalogs[currentCatalogName][key] = value
            }
        }
    }

    return catalogs
}

function createPublishManifest(manifest, catalogs) {
    const result = JSON.parse(JSON.stringify(manifest))
    resolveCatalogs(result, catalogs || {})
    applyPublishConfig(result)
    stripPnpmFields(result)
    return result
}

// CLI: create_publish_manifest <package-json> <output> [pnpm-workspace-yaml]
const packageJsonPath = process.argv[2]
const outputPath = process.argv[3]
const workspaceYamlPath = process.argv[4]

if (!packageJsonPath || !outputPath) {
    console.error(
        'Usage: create_publish_manifest <package-json> <output> [pnpm-workspace-yaml]'
    )
    process.exit(1)
}

const manifest = JSON.parse(readFileSync(packageJsonPath, 'utf8'))

let catalogs = {}
if (workspaceYamlPath && existsSync(workspaceYamlPath)) {
    const content = readFileSync(workspaceYamlPath, 'utf8')
    catalogs = parseCatalogsFromWorkspaceYaml(content)
}

const result = createPublishManifest(manifest, catalogs)
writeFileSync(outputPath, JSON.stringify(result, null, 4) + '\n')
