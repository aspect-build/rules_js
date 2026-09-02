// Stands in for a runtime transpiler such as ts-node: compiles transpiled_lib.js from
// memory with a banner line prepended, so every V8 offset in it is one line further down
// than the file on disk. Nothing on disk holds the generated code or a
// //# sourceMappingURL for the reporter to find, so node's own record of the mapping,
// which coverage.cjs writes into the profile, is the only way back to the real lines.
// transpiled_merger asserts them.
const fs = require('node:fs')
const path = require('node:path')
const Module = require('node:module')

const filename = path.resolve(__dirname, 'transpiled_lib.js')
const source = fs.readFileSync(filename, 'utf8')

// Generated line n is original line n - 1. A mapping segment is (generated column, source
// index, source line, source column), each a delta from the previous segment, so 'AAAA' is
// four zeroes and 'AACA' is the same one source line further on. The leading ';' ends the
// banner's line, which maps to nothing.
const map = {
    version: 3,
    sources: [filename],
    names: [],
    mappings: ';AAAA' + ';AACA'.repeat(source.split('\n').length - 1),
}
const generated =
    '// prepended by transpiled.js\n' +
    source +
    '\n//# sourceMappingURL=data:application/json;base64,' +
    Buffer.from(JSON.stringify(map)).toString('base64') +
    '\n'

const lib = new Module(filename, module)
lib._compile(generated, filename)

lib.exports.transpiledCovered()
