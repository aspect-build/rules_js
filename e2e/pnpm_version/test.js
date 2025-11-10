const lockfileContent = require('fs').readFileSync('pnpm-lock.yaml', 'utf8')

const lockfileVersion = lockfileContent.match(/lockfileVersion: '([^']+)'/)

if (!lockfileVersion || lockfileVersion[1] !== '9.0') {
    throw new Error('Incorrect pnpm version: ' + lockfileVersion[1])
}
