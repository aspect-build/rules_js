import assert from 'node:assert'
import { createReadStream } from 'node:fs'
import { createGunzip } from 'node:zlib'
import tar from 'tar-stream'

const extract = tar.extract()

const node_modules_entries = new Map()
extract.on('entry', (header, stream, next) => {
    node_modules_entries.set(header.name, header)
    stream.resume()
    next()
})

createReadStream(process.argv[3]).pipe(createGunzip()).pipe(extract)

await new Promise((resolve) => extract.on('finish', resolve))

const symlink = node_modules_entries.get(
    'app/js/private/test/image/bin.runfiles/aspect_rules_js/js/private/test/image/node_modules/acorn'
)

assert.ok(!!symlink)
assert.equal(symlink.type, 'symlink')
assert.equal(symlink.mtime.getTime(), new Date(0).getTime())
assert.equal(
    symlink.linkname,
    'app/js/private/test/image/bin.runfiles/aspect_rules_js/node_modules/.aspect_rules_js/acorn@8.8.2/node_modules/acorn'
)
