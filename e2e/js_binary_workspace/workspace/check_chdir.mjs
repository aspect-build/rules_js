import { readFileSync } from 'fs';
import { join } from 'path';

const runfiles = process.env.JS_BINARY__RUNFILES;
const expectedFile = join(runfiles, process.argv[2]);
const expected = readFileSync(expectedFile, 'utf8').trim();
const cwd = process.cwd();

if (!cwd.endsWith(expected)) {
    process.stderr.write(`Expected cwd to end with:\n  ${expected}\nActual cwd:\n  ${cwd}\n`);
    process.exit(1);
}
