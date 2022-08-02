import crypto from "crypto";
import {
  readFileSync,
  mkdirSync,
  existsSync,
  copyFileSync,
  writeFileSync,
  createWriteStream,
  unlink,
} from "fs";
import https from "https";
import { resolve } from "path";

/**
 * Create a bcr entry for a new version of this repository.
 *
 * Usage: create-bcr-entry [project_path] [bcr_path] [owner_slash_repo] [tag]
 *
 *   project_path: path to the project's repository; should contain a
 *      root level MODULE.bazel file and a .github/workflows/bcr folder
 *      with templated bcr entry files.
 *   bcr_path: path to the bcr repository
 *   owner_slash_repo: the github owner/repository name of the project
 *   tag: the github tag for this version, e.g., "v1.0.0" or "1.0.0"
 *
 */
async function main(argv) {
  if (argv.length !== 4) {
    console.error(
      "usage: create-bcr-entry [project_path] [bcr_path] [owner_slash_repo] [tag]"
    );
    process.exit(1);
  }

  const [projectPath, bcrPath, ownerSlashRepo, tag] = argv;
  const version = getVersionFromTag(tag);

  const moduleName = getModuleName(resolve(projectPath, "MODULE.bazel"));
  const bcrTemplatesPath = resolve(projectPath, ".github/workflows/bcr");
  const bcrEntryPath = resolve(bcrPath, "modules", moduleName);
  const bcrVersionEntryPath = resolve(bcrEntryPath, version);

  if (!existsSync(bcrEntryPath)) {
    mkdirSync(bcrEntryPath);
  }

  updateMetadataFile(
    resolve(bcrTemplatesPath, "metadata.template.json"),
    resolve(bcrEntryPath, "metadata.json"),
    version
  );

  mkdirSync(bcrVersionEntryPath);

  stampModuleFile(
    resolve(projectPath, "MODULE.bazel"),
    resolve(bcrVersionEntryPath, "MODULE.bazel"),
    version
  );

  await stampSourceFile(
    resolve(bcrTemplatesPath, "source.template.json"),
    resolve(bcrVersionEntryPath, "source.json"),
    ownerSlashRepo,
    version,
    tag
  );

  // Copy over the presubmit file
  copyFileSync(
    resolve(bcrTemplatesPath, "presubmit.yml"),
    resolve(bcrVersionEntryPath, "presubmit.yml")
  );
}

function getModuleName(modulePath) {
  const moduleContent = readFileSyncOrFail(
    modulePath,
    "Cannot find MODULE.bazel; bzlmod requires this file at the root of your workspace."
  );

  const regex = /module\(.*?name\s*=\s*"(\w+)"/s;
  const match = moduleContent.match(regex);
  if (match) {
    return match[1];
  }
  throw new Error("Could not parse module name from module file");
}

function updateMetadataFile(sourcePath, destPath, version) {
  let publishedVersions = [];
  if (existsSync(destPath)) {
    const existingMetadata = JSON.parse(
      readFileSync(destPath, { encoding: "utf-8" })
    );
    publishedVersions = existingMetadata.versions;
  }

  if (publishedVersions.includes(version)) {
    console.error(`Version ${version} is already published to this registry`);
    process.exit(1);
  }

  const metadata = JSON.parse(
    readFileSyncOrFail(sourcePath),
    `Cannot find metadata template ${sourcePath}; did you forget to create it?`
  );
  metadata.versions = [...publishedVersions, version];

  writeFileSync(destPath, JSON.stringify(metadata, null, 4) + "\n");
}

function stampModuleFile(sourcePath, destPath, version) {
  const module = readFileSyncOrFail(
    sourcePath,
    "Cannot find MODULE.bazel; bzlmod requires this file at the root of your workspace."
  );

  const stampedModule = module.replace(
    /(^.*?module\(.*?version\s*=\s*")[\w.]+(".*$)/s,
    `$1${version}$2`
  );

  writeFileSync(destPath, stampedModule, {
    encoding: "utf-8",
  });
}

async function stampSourceFile(
  sourcePath,
  destPath,
  ownerSlashRepo,
  version,
  tag
) {
  const owner = ownerSlashRepo.substring(0, ownerSlashRepo.indexOf("/"));
  const repo = ownerSlashRepo.substring(ownerSlashRepo.indexOf("/") + 1);

  // Substitute variables into source.json
  const sourceContent = readFileSyncOrFail(
    sourcePath,
    `Cannot find source template ${sourcePath}; did you forget to create it?`
  );
  const substituted = sourceContent
    .replace(/{REPO}/g, repo)
    .replace(/{OWNER}/g, owner)
    .replace(/{VERSION}/g, version)
    .replace(/{TAG}/g, tag);

  // Compute the integrity hash
  const sourceJson = JSON.parse(substituted);
  const filename = sourceJson.url.substring(
    sourceJson.url.lastIndexOf("/") + 1
  );

  console.log(`Downloading archive ${sourceJson.url}`);
  await download(sourceJson.url, filename);
  console.log("Finished downloading");

  const hash = crypto.createHash("sha256");
  hash.update(readFileSync(filename));
  const digest = hash.digest("base64");
  sourceJson.integrity = `sha256-${digest}`;

  writeFileSync(destPath, JSON.stringify(sourceJson, undefined, 4), {
    encoding: "utf-8",
  });
}

function getVersionFromTag(version) {
  if (version.startsWith("v")) {
    return version.substring(1);
  }
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const request = https.get(url, (response) => {
      if (response.statusCode === 200) {
        const file = createWriteStream(dest, { flags: "wx" });
        file.on("finish", () => resolve());
        file.on("error", (err) => {
          file.close();
          unlink(dest, () => reject(err.message));
          reject(err);
        });
        response.pipe(file);
      } else if (response.statusCode === 302 || response.statusCode === 301) {
        // Redirect
        download(response.headers.location, dest).then(() => resolve());
      } else {
        reject(
          `Server responded with ${response.statusCode}: ${response.statusMessage}`
        );
      }
    });

    request.on("error", (err) => {
      reject(err.message);
    });
  });
}

function readFileSyncOrFail(filename, notExistsMsg) {
  try {
    return readFileSync(filename, { encoding: "utf-8" });
  } catch (error) {
    if (error.code === "ENOENT") {
      console.error(notExistsMsg);
      process.exit(1);
    }
    throw error;
  }
}

(async () => {
  const argv = process.argv.slice(2);
  try {
    await main(argv);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
