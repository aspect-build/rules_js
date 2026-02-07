// entry.mjs -- ESM sandbox integration test for issue #362
//
// Verifies that ESM imports resolve correctly within the Bazel sandbox
// and that fs.realpathSync.native() does not escape the sandbox.
//
// Issue #362: Node.js ESM resolver captures realpathSync.native() via
// destructuring BEFORE --require patches run, so resolved paths escape
// the Bazel sandbox. The native FS sandbox (LD_PRELOAD) fixes this by
// intercepting libc realpath() at the C level.

import { depUrl } from "./dep.mjs";
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";

let passed = true;

function check(description, condition) {
    if (condition) {
        console.log(`  PASS: ${description}`);
    } else {
        console.log(`  FAIL: ${description}`);
        passed = false;
    }
}

console.log("ESM sandbox test (issue #362):");

// The FS_PATCH_ROOTS env var contains the sandbox roots (colon-separated).
// Paths returned by realpathSync must stay within these roots.
// This env var MUST be set by the js_binary launcher — if it's missing,
// the native sandbox is not active and the test should fail.
const rootsEnv = process.env.JS_BINARY__FS_PATCH_ROOTS;
if (!rootsEnv) {
    console.log("  FAIL: JS_BINARY__FS_PATCH_ROOTS is not set — native sandbox not active");
    process.exit(1);
}
const roots = rootsEnv.split(":").filter(Boolean);
if (roots.length === 0) {
    console.log("  FAIL: JS_BINARY__FS_PATCH_ROOTS is empty — no sandbox roots configured");
    process.exit(1);
}
console.log(`  configured roots: ${roots.length}`);

function isWithinRoots(p) {
    return roots.some(root => p.startsWith(root));
}

// Get file paths from import.meta.url
const entryPath = fileURLToPath(import.meta.url);
const depPath = fileURLToPath(depUrl);
const entryDir = dirname(entryPath);

console.log(`  entry path: ${entryPath}`);
console.log(`  dep path:   ${depPath}`);

// Verify import.meta.url is a file:// URL
check(
    "entry import.meta.url is file:// URL",
    import.meta.url.startsWith("file://")
);
check(
    "dep import.meta.url is file:// URL",
    depUrl.startsWith("file://")
);

// Verify dep.mjs is in the same directory as entry.mjs
check(
    "dep.mjs is in same directory as entry.mjs",
    depPath.startsWith(entryDir)
);

// ---- CORE TEST for issue #362 ----
// realpathSync.native() is what the ESM resolver uses internally.
// Without the native FS sandbox, this would resolve through symlinks
// to the real execroot OUTSIDE the sandbox. With our fix, it should
// return a path that stays within the configured roots.
try {
    const realNative = realpathSync.native(entryPath);
    console.log(`  realpathSync.native: ${realNative}`);

    check(
        "realpathSync.native() returns a valid path",
        typeof realNative === "string" && realNative.length > 0
    );

    check(
        "realpathSync.native() stays within sandbox roots",
        isWithinRoots(realNative)
    );
} catch (err) {
    console.log(`  FAIL: realpathSync.native() threw: ${err.message}`);
    passed = false;
}

// Also verify the JS-level realpathSync (patched by --require)
try {
    const realJS = realpathSync(entryPath);
    console.log(`  realpathSync:        ${realJS}`);

    check(
        "realpathSync() returns a valid path",
        typeof realJS === "string" && realJS.length > 0
    );

    check(
        "realpathSync() stays within sandbox roots",
        isWithinRoots(realJS)
    );
} catch (err) {
    console.log(`  FAIL: realpathSync() threw: ${err.message}`);
    passed = false;
}

if (passed) {
    console.log("PASS: All ESM sandbox checks passed.");
    process.exit(0);
} else {
    console.log("FAIL: Some ESM sandbox checks failed.");
    process.exit(1);
}
