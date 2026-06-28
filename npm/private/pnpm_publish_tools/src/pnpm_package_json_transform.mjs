import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

let createExportableManifest;
try {
  // pnpm 11+
  ({ createExportableManifest } = await import(
    '@pnpm/releasing.exportable-manifest'
  ));
} catch {
  // pnpm 10
  ({ createExportableManifest } = await import(
    '@pnpm/exportable-manifest'
  ));
}

function resolvePath(p) {
  if (path.isAbsolute(p)) return p;
  const execroot = process.env.JS_BINARY__EXECROOT;
  if (execroot) return path.resolve(execroot, p);
  return path.resolve(p);
}

const args = process.argv.slice(2);
let catalogsJsonArg, packageJsonArg, outputArg, versionArg;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--catalogs-json') catalogsJsonArg = args[++i];
  else if (args[i] === '--package-json') packageJsonArg = args[++i];
  else if (args[i] === '--output') outputArg = args[++i];
  else if (args[i] === '--version') versionArg = args[++i];
}

if (!catalogsJsonArg || !packageJsonArg || !outputArg) {
  process.stderr.write(
    'usage: pnpm_package_json_transform --catalogs-json <path> --package-json <path> --output <path> [--version <ver>]\n'
  );
  process.exit(1);
}

const catalogsJsonPath = resolvePath(catalogsJsonArg);
const packageJsonPath = resolvePath(packageJsonArg);
const outputPath = resolvePath(outputArg);
const packageDir = path.dirname(packageJsonPath);

const catalogs = JSON.parse(readFileSync(catalogsJsonPath, 'utf8'));
const manifest = JSON.parse(readFileSync(packageJsonPath, 'utf8'));

if (versionArg) {
  manifest.version = versionArg;
}

const exportedManifest = await createExportableManifest(packageDir, manifest, {
  catalogs,
});

const depFields = new Set([
  'dependencies',
  'devDependencies',
  'peerDependencies',
  'optionalDependencies',
]);

for (const field of depFields) {
  const deps = exportedManifest[field];
  if (deps && typeof deps === 'object' && !Array.isArray(deps)) {
    const sorted = {};
    for (const key of Object.keys(deps).sort()) {
      sorted[key] = deps[key];
    }
    exportedManifest[field] = sorted;
  }
}

writeFileSync(outputPath, `${JSON.stringify(exportedManifest, null, 2)}\n`);
