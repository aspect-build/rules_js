const { readFileSync } = require('node:fs')
exports.test = readFileSync(`${__dirname}/test.txt`, 'utf-8')
