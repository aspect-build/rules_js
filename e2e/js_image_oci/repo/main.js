const acorn = require("acorn")
const result = acorn.parse("1 + 1", { ecmaVersion: 2020 })
process.stdout.write(JSON.stringify(result) + "\n")
