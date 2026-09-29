import { execFileSync } from 'node:child_process'
import { writeFileSync } from 'node:fs'
import path from 'node:path'

// Verify that we can find sh on the PATH
const hostTool = execFileSync('sh', ['-c', 'echo host tool ok'], { encoding: 'utf8' })

// Invoke the js_binary provided as a command-line argument
const launcher = path.join(process.env.JS_BINARY__RUNFILES, process.argv[2])
const inner = execFileSync(launcher, [], { encoding: 'utf8' })

writeFileSync(path.join(process.env.JS_BINARY__EXECROOT, process.argv[3]), hostTool + inner)
