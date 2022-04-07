const {link} = require("@rules_js/linker");

console.log(process.cwd());

link();

require("rollup/dist/bin/rollup");