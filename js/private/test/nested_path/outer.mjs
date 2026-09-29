import { execFileSync } from 'node:child_process'
import path from 'node:path'

// Verify that we can find sh on the PATH
process.stdout.write(execFileSync('sh', ['-c', 'echo host tool ok'], { encoding: 'utf8' }))

// Invoke the js_binary provided as a command-line argument
const launcher = path.join(process.env.JS_BINARY__RUNFILES, process.argv[2])
process.stdout.write(execFileSync(launcher, [], { encoding: 'utf8' }))
