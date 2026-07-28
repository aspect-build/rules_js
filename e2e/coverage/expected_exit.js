const assert = require('node:assert')
const lib = require('./lib.js')

assert.strictEqual(lib.covered(), 'covered')

// Exit non-zero on purpose; the js_test's expected_exit_code matches, so the test
// passes and coverage must still be produced for it. See #2932.
process.exit(42)
