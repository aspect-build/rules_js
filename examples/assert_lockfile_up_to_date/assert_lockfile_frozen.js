const path = require('path');
const fs = require('fs');
const child_process  = require('child_process');
const readline = require('readline');

const FIX_COMMAND = 'bazel run //examples/assert_lockfile_up_to_date:update_pnpm_lockfile'

// https://github.com/pnpm/pnpm/blob/8fa95fd868d1afac6f7454ac17f77f8a017d2110/packages/headless/src/index.ts#L166
const OUTDATED_LOCKFILE_ERR_CODE = "ERR_PNPM_OUTDATED_LOCKFILE"

// pnpm does not offer a no-install method to assert that a lockfile
// is up-to-date, so we need to trick it a bit.
// See: https://github.com/pnpm/pnpm/issues/4861
//
// When using --frozen-lockfile, pnpm will perform the lockfile check before
// attempting to download any packages. We use that flag and force it offline,
// then look at its jsonl log output for the error code specific to an outdated
// lockfile.
//
// When the lockfile is out-of-date, it will fail early with the error message about that.
// When the lockfile is up-to-date, it will fail quickly because it is in offline mode
// and cannot find anything in our empty store directory.
const forkedPnpm = child_process.fork(require.resolve('pnpm'),
    [
        'install',
        '--offline',
        '--frozen-lockfile',
        '--reporter',
        'ndjson',
        // set the store dir to be in the bazel build output directory so it doesn't pull
        // from the user location.
        '--store-dir',
        path.join(process.cwd(), 'store'),
    ],
    {stdio: ['ignore', 'pipe', 'ignore', 'ipc']},
);

const stdout  = readline.createInterface({
    input: forkedPnpm.stdout,
});

var lockfileOutOfDate = false;

stdout.on('line', (line) => {
    message = JSON.parse(line)
    if (message.code == OUTDATED_LOCKFILE_ERR_CODE) {
        lockfileOutOfDate = true;
    }
});

stdout.on('close', (line) => {
    if (!lockfileOutOfDate) {
        process.exit(0)
    }

    console.log(`pnpm lockfile is out of date. Run the following to update it:

    ${FIX_COMMAND}
`)
    process.exit(1)
});
