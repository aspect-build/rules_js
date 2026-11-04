// Writes files of its own into COVERAGE_DIR, as a framework that reports its own
// coverage might. coverage-final.json is the name Istanbul writes.
const fs = require('node:fs')
const path = require('node:path')

if (process.env.COVERAGE_DIR) {
    fs.mkdirSync(process.env.COVERAGE_DIR, { recursive: true })
    fs.writeFileSync(
        path.join(process.env.COVERAGE_DIR, 'coverage-final.json'),
        '{}'
    )
    fs.writeFileSync(
        path.join(process.env.COVERAGE_DIR, 'coverage-1-2.json'),
        '{}'
    )
}
