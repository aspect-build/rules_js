// Importing segfault-handler fails with `Error: Could not locate the bindings file.`
// if `node-gyp rebuild` has not been run.
const segfaultHandler = require('segfault-handler')
