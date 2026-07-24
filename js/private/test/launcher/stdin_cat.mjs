// Echoes stdin to stdout, verifying the launcher passes its own stdin through
// to node rather than detaching it.
import fs from 'node:fs'
process.stdout.write(fs.readFileSync(0))
