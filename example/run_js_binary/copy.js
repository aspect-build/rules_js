const fs = require('fs')
const [inFile, outFile] = process.argv.slice(2)
console.log(`${inFile} -> ${outFile}`)
fs.writeFileSync(outFile, fs.readFileSync(inFile))
