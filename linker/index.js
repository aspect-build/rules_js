const fs = require("fs");
const p = require("path").posix;

const default_link_into = p.join(process.cwd(), "node_modules");
const default_link_from = process.env.MERGED_NODE_MODULES;

exports.link = function(from = default_link_from, into = default_link_into) {
    console.log(`LINKER: linking into ${into}`);
    console.log(`LINKER: linking from ${process.env.MERGED_NODE_MODULES}`)
    fs.symlinkSync(from, into);
}
