import { execFileSync } from 'node:child_process'
import path from 'node:path'

// A host tool by name, found only through the PATH this process was given.
process.stdout.write(execFileSync('sh', ['-c', 'echo host tool ok'], { encoding: 'utf8' }))

const launcher = path.join(process.env.JS_BINARY__RUNFILES, process.argv[2])
process.stdout.write(execFileSync(launcher, [], { encoding: 'utf8' }))
