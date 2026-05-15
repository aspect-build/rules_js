import fs from 'fs'

const content = fs.readFileSync(process.argv[2], 'utf8').trim()
process.stdout.write(content + '\n')
