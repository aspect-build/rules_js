const path = require('path');
const fs = require('fs');

const { fork } = require('child_process');

// Copy the pnpm-lock.yaml file into a workdir so that
// pnpm can edit it -- for some reason, pnpm hits permission issues
// if it tries to write to the original pnpm-lock.yaml file.
fs.mkdirSync('workdir');
fs.copyFileSync('pnpm-lock.yaml', 'workdir/pnpm-lock.yaml');
fs.copyFileSync('package.json', 'workdir/package.json');
fs.rmSync('package.json')


const forkedPnpm = fork(require.resolve('pnpm'), [
    'install',
    '--lockfile-only',
    '--color',
    '--dir',
    'workdir',
    '--store-dir',
    path.join(process.cwd(), 'store'),
    ],
);

forkedPnpm.on('exit', (code) => {
    if (code !== 0) {
        process.exit(code);
    }

    fs.copyFileSync('workdir/pnpm-lock.yaml', 'output-pnpm-lock.yaml');
    process.exit(0);
});
