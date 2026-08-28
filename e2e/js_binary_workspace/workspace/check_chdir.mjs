import { realpathSync } from 'fs';
import { dirname, join } from 'path';

// This is a js_test in an external repository, so it runs in the runfiles tree, where the
// repository is a top-level directory beside the main one rather than under external/. argv[2] is
// the rlocationpath of a file in this package, whose first segment is that directory.
const runfiles = process.env.JS_BINARY__RUNFILES;

// Compare realpaths: process.cwd() is the resolved physical path, while JS_BINARY__RUNFILES is
// derived from $0 and may still contain symlinks.
const expected = realpathSync(join(runfiles, dirname(process.argv[2])));
const cwd = realpathSync(process.cwd());

if (cwd !== expected) {
    process.stderr.write(`Expected cwd:\n  ${expected}\nActual cwd:\n  ${cwd}\n`);
    process.exit(1);
}
