// Regression test for js/private/js_image_layer_tar.mjs -- the Node guard that
// wraps bsdtar for js_image_layer's tar-create actions and turns bsdtar's SILENT
// st_ino==0 corruption on Windows/NTFS into a hard build failure.
//
// The corruption itself only reproduces on Windows with degenerate NTFS inodes,
// so this test asserts the guard's two detection predicates against the exact
// observable signatures (the real "Can't add archive to itself" stderr line seen
// in CI, and a realistic `tar -tvf` hardlink listing), plus the benign cases that
// must NOT trip it (ordinary warnings, symlinks, regular files).
//
// Cross-platform and deterministic: no subprocess/tar spawn. Runs under
// `bazel test` (js_test) or directly via `node js_image_layer_tar_guard_test.mjs`.

import { isSelfReferenceDrop, findHardlinkLines } from '../../js_image_layer_tar_lib.mjs'

let failures = 0
function check(desc, cond) {
    if (cond) {
        console.log(`ok: ${desc}`)
    } else {
        failures++
        console.error(`FAIL: ${desc}`)
    }
}

// --- self-reference (silent drop) detection ---------------------------------
check(
    'self-ref: real CI stderr line is detected',
    isSelfReferenceDrop(
        "tar.exe: .../stack-trace@0.0.10/node_modules/stack-trace/lib/stack-trace.js: Can't add archive to itself"
    )
)
check('self-ref: bare message is detected', isSelfReferenceDrop("foo: Can't add archive to itself\n"))
check('self-ref: empty stderr is NOT flagged', !isSelfReferenceDrop(''))
check(
    'self-ref: benign "Removing leading /" warning is NOT flagged',
    !isSelfReferenceDrop("tar.exe: Removing leading '/' from member names\n")
)

// --- hardlink-member detection ----------------------------------------------
const CLEAN_LISTING = [
    '-r-xr-xr-x  0 0      0          12 Jan  1  1970 ./a.js',
    '-r-xr-xr-x  0 0      0          20 Jan  1  1970 ./main.js',
    'drwxr-xr-x  0 0      0           0 Jan  1  1970 ./dir',
].join('\n')

const SYMLINK_LISTING = [
    '-r-xr-xr-x  0 0      0          12 Jan  1  1970 ./a.js',
    'lrwxr-xr-x  0 0      0           0 Jan  1  1970 ./node_modules/x -> ../x@1.0.0/node_modules/x',
].join('\n')

const HARDLINK_LISTING = [
    '-r-xr-xr-x  0 0      0          12 Jan  1  1970 ./a.js',
    'hr-xr-xr-x  0 0      0           0 Jan  1  1970 ./b.js link to ./a.js',
].join('\n')

check('hardlink: clean listing has 0 hardlinks', findHardlinkLines(CLEAN_LISTING).length === 0)
check('hardlink: symlink listing has 0 hardlinks (symlinks are legitimate)', findHardlinkLines(SYMLINK_LISTING).length === 0)
check('hardlink: hardlink member is detected', findHardlinkLines(HARDLINK_LISTING).length === 1)

if (failures > 0) {
    console.error(`\n${failures} assertion(s) failed`)
    process.exit(1)
}
console.log('\nall js_image_layer_tar guard assertions passed')
