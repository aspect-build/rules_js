import { realpathSync } from 'fs';
import { dirname, join } from 'path';

const runfiles = process.env.JS_BINARY__RUNFILES;

// Compare resolved physical paths since JS_BINARY__RUNFILES may contain symlinks.
const expected = realpathSync(join(runfiles, dirname(process.argv[2])));
const cwd = realpathSync(process.cwd());

if (cwd !== expected) {
    process.stderr.write(`Expected cwd:\n  ${expected}\nActual cwd:\n  ${cwd}\n`);
    process.exit(1);
}
