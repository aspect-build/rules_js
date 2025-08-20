import fs from 'fs'
import path from 'path'
import crypto from 'crypto'

function sha256(filePath) {
    const hash = crypto.createHash('sha256')
    hash.update(fs.readFileSync(filePath))
    return hash.digest('hex')
}

const dgramPath = new URL(import.meta.resolve('unix-dgram/build/Makefile')).pathname

console.log()
console.log('Path:', dgramPath)
console.log(`SHA256:${sha256(dgramPath)}`)
console.log()
