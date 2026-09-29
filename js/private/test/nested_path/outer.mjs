import { execFileSync } from 'node:child_process'
import path from 'node:path'

const launcher = path.join(process.env.JS_BINARY__RUNFILES, process.argv[2])
process.stdout.write(execFileSync(launcher, [], { encoding: 'utf8' }))
