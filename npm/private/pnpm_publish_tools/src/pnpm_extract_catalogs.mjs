import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

import { getCatalogsFromWorkspaceManifest } from '@pnpm/catalogs.config';
import { readWorkspaceManifest } from '@pnpm/workspace.read-manifest';

function resolvePath(p) {
  if (path.isAbsolute(p)) return p;
  const execroot = process.env.JS_BINARY__EXECROOT;
  if (execroot) return path.resolve(execroot, p);
  return path.resolve(p);
}

const args = process.argv.slice(2);
let workspaceManifestArg, outputArg;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--workspace-manifest') workspaceManifestArg = args[++i];
  else if (args[i] === '--output') outputArg = args[++i];
}

if (!workspaceManifestArg || !outputArg) {
  process.stderr.write(
    'usage: pnpm_extract_catalogs --workspace-manifest <path> --output <path>\n'
  );
  process.exit(1);
}

const workspaceManifestPath = resolvePath(workspaceManifestArg);
const workspaceDir = path.dirname(workspaceManifestPath);
const outputPath = resolvePath(outputArg);

const workspaceManifest = await readWorkspaceManifest(workspaceDir);
const catalogs = getCatalogsFromWorkspaceManifest(workspaceManifest);

writeFileSync(outputPath, `${JSON.stringify(catalogs, null, 2)}\n`);
