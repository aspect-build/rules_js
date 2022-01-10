const pkg_that_i_need = require("acorn");
const pkg_that_i_to_typecheck = require("@gregmagolan/test-b");
console.log(pkg_that_i_need.version, pkg_that_i_to_typecheck);


require("fs").writeFileSync(process.argv[process.argv.length - 1], "hello world!")