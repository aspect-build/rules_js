const fs = require('node:fs')
const path = require('node:path')
const assert = require('node:assert/strict')

// Finding the tool must not change the consuming action's working directory.
assert.ok(
    process
        .cwd()
        .split(path.sep)
        .join('/')
        .endsWith(process.env.BAZEL_BINDIR.split(path.sep).join('/'))
)
fs.writeFileSync(process.argv[2], 'generated in target configuration')
