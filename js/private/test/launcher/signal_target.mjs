// Stays alive until it receives the signal named by argv[2] (default SIGTERM),
// then reports that node's own handler ran before exiting. Used by
// signal_driver.mjs to verify the js_binary launcher forwards a directed
// termination signal through to node.
const signal = process.argv[2] || 'SIGTERM'

process.on(signal, () => {
    // Exit from the write callback so the HANDLED marker is flushed to the
    // stdout pipe before the process terminates.
    process.stdout.write('HANDLED\n', () => process.exit(0))
})

process.stdout.write('READY\n')

// Keep the event loop alive so the process does not exit on its own.
setInterval(() => {}, 1 << 30)
