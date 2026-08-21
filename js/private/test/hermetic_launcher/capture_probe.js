// Entry point for the capture differential test: the same js_binary runs twice, once
// through each launcher, with stdout, stderr and the exit code all captured by
// run_binary's spawn_binary wrapper rather than by the launcher script. The three
// captured files must be byte-identical across the two runs, which is what says the
// wrapper behaves the same whether it is forking the script or the hermetic stub.
//
// Nothing written to the streams may depend on which launcher ran, so paths stay out
// of them.

const fs = require('fs')
const path = require('path')

// The one argument is where to record which launcher ran. That cannot go on the
// captured streams, since those are what the differential test compares.
const launcherOut = process.argv[2]

// Interleaved, so that a wrapper which crossed the two streams would show up as a
// difference in both files rather than as a line missing from one.
process.stdout.write('capture: first line on stdout\n')
process.stderr.write('capture: first line on stderr\n')
process.stdout.write('capture: second line on stdout\n')
process.stderr.write('capture: second line on stderr\n')

fs.mkdirSync(path.dirname(launcherOut), { recursive: true })
fs.writeFileSync(launcherOut, path.basename(process.env.JS_BINARY__NODE_PATCHES) + '\n')

// A non-zero exit the action has to survive: exit_code_out records the code and leaves
// the action successful. Set rather than passed to process.exit() so that node flushes
// the streams on the way out. 42 rather than 1, so a code invented somewhere along the
// chain cannot pass for it.
process.exitCode = 42
