import assert from 'node:assert'
import { t } from 'tar'

const EPOCH_START = new Date(0)

const app_entries = new Array()
await t({
    file: process.argv[2],
    onentry: (entry) => app_entries.push(entry),
})

const node_modules_entries = new Array()
await t({
    file: process.argv[3],
    onentry: (entry) => node_modules_entries.push(entry),
})

for (const entry of app_entries) {
    assert.ok(entry.mtime instanceof Date)
    assert.ok(entry.mtime.getTime() == EPOCH_START.getTime())
}

for (const entry of node_modules_entries) {
    assert.ok(entry.mtime instanceof Date)
    assert.ok(entry.mtime.getTime() == EPOCH_START.getTime())
}
