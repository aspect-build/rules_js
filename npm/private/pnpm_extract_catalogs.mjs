import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, dirname, isAbsolute } from 'node:path'

function resolvePath(p) {
  if (isAbsolute(p)) return p
  const execroot = process.env.JS_BINARY__EXECROOT
  if (execroot) return resolve(execroot, p)
  return resolve(p)
}

const args = process.argv.slice(2)
let workspaceManifestArg, outputArg
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--workspace-manifest') workspaceManifestArg = args[++i]
  else if (args[i] === '--output') outputArg = args[++i]
}

if (!workspaceManifestArg || !outputArg) {
  process.stderr.write(
    'usage: pnpm_extract_catalogs --workspace-manifest <path> --output <path>\n'
  )
  process.exit(1)
}

const content = readFileSync(resolvePath(workspaceManifestArg), 'utf8')
const catalogs = {}
const lines = content.split('\n')
let i = 0

while (i < lines.length) {
  const line = lines[i]
  const stripped = line.trimStart()
  const indent = line.length - stripped.length

  if (indent === 0 && stripped === 'catalog:') {
    const entries = {}
    i++
    while (i < lines.length) {
      const child = lines[i]
      const cs = child.trimStart()
      if (cs === '' || cs.startsWith('#')) { i++; continue }
      const ci = child.length - cs.length
      if (ci <= indent) break
      const colon = cs.indexOf(':')
      if (colon !== -1) {
        entries[cs.slice(0, colon).trim().replace(/^['"]|['"]$/g, '')] =
          cs.slice(colon + 1).trim().replace(/^['"]|['"]$/g, '')
      }
      i++
    }
    if (Object.keys(entries).length) catalogs.default = entries
    continue
  }

  if (indent === 0 && stripped === 'catalogs:') {
    i++
    while (i < lines.length) {
      const child = lines[i]
      const cs = child.trimStart()
      if (cs === '' || cs.startsWith('#')) { i++; continue }
      const ci = child.length - cs.length
      if (ci <= indent) break
      const catalogName = cs.replace(/:$/, '').trim().replace(/^['"]|['"]$/g, '')
      const entries = {}
      i++
      while (i < lines.length) {
        const gc = lines[i]
        const gs = gc.trimStart()
        if (gs === '' || gs.startsWith('#')) { i++; continue }
        const gi = gc.length - gs.length
        if (gi <= ci) break
        const colon = gs.indexOf(':')
        if (colon !== -1) {
          entries[gs.slice(0, colon).trim().replace(/^['"]|['"]$/g, '')] =
            gs.slice(colon + 1).trim().replace(/^['"]|['"]$/g, '')
        }
        i++
      }
      if (Object.keys(entries).length) catalogs[catalogName] = entries
    }
    continue
  }

  i++
}

writeFileSync(resolvePath(outputArg), JSON.stringify(catalogs, null, 2) + '\n')
