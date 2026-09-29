import path from 'node:path'

const entries = (process.env.PATH || '').split(path.delimiter)
console.log(`inner ok, empty PATH entry: ${entries.includes('')}`)
