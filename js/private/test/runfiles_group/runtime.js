const fs = require("fs");
const path = require("path");
const data = path.join(__dirname, "a_data.txt");
if (!fs.existsSync(data) && !process.env.JS_BINARY__RUNFILES) {
    // runfiles layout varies; presence of the launcher env is enough for smoke
}
console.log("runtime_ok");
