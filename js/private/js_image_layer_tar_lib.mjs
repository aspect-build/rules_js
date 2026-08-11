// Pure detection predicates for the js_image_layer tar guard.
//
// Kept in a separate library module (not js_image_layer_tar.mjs) so unit tests
// can import these predicates WITHOUT the CLI's top-level main() executing. The
// usual ESM "am I the entry point?" self-check
// (`path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)`) is
// unreliable under Bazel on Windows: Node realpath's the main entry through the
// `external/<repo>` junction, so import.meta.url and process.argv[1] disagree and
// main() would silently never run. Splitting lib/bin sidesteps that entirely.
//
// See js_image_layer_tar.mjs for the full rationale on why the guard exists.

// libarchive's self-reference guard message. When bsdtar prints this it has
// SILENTLY skipped the named input file, so the archive is missing content.
export const SELF_REFERENCE_RE = /Can't add archive to itself/

/**
 * True if tar's stderr shows it silently dropped a file via the self-reference guard.
 * @param {string} stderr
 * @returns {boolean}
 */
export function isSelfReferenceDrop(stderr) {
    return SELF_REFERENCE_RE.test(stderr || '')
}

/**
 * Return the hardlink member lines from a `tar -tvf` verbose listing. A hardlink
 * renders as `<path> link to <target>` (distinct from a symlink's `<path> -> <target>`)
 * with an `h` file-type char, e.g. `hr-xr-xr-x  0 0 0 0 <date> ./b link to ./a`.
 * @param {string} listing
 * @returns {string[]}
 */
export function findHardlinkLines(listing) {
    return (listing || '')
        .split('\n')
        .filter((l) => / link to /.test(l) || /^\s*h[rwxsStT-]{9}\s/.test(l))
}
