// Test that AspectWatchProtocol.connect() failures reject catchably instead of
// emitting an unhandled socket 'error' event that crashes the process.
import * as os from 'node:os'
import * as path from 'node:path'
import * as assert from 'node:assert'
import { AspectWatchProtocol } from '../../watch/aspect_watch_protocol.mjs'

const missingSocket = path.join(
    os.tmpdir(),
    `watch-proto-test-${process.pid}-missing.sock`
)

const w = new AspectWatchProtocol(missingSocket)
await assert.rejects(() => w.connect(), /ENOENT|ECONNREFUSED/)

// Give any stray async 'error' event a chance to crash us if mishandled.
await new Promise((r) => setTimeout(r, 50))

console.log('PASS: connect() to missing socket rejects catchably')
