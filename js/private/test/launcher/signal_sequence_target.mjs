// Reports SIGINT without exiting, then exits with the launcher's expected_exit_code on
// SIGTERM. See signal_sequence_driver.mjs.
process.on('SIGINT', () => process.stdout.write('GOT_INT\n'))

process.on('SIGTERM', () => {
    // Exit from the write callback so the marker is flushed to the stdout pipe
    // before the process terminates.
    process.stdout.write('HANDLED\n', () => process.exit(42))
})

process.stdout.write('READY\n')

// Keep the event loop alive so the process does not exit on its own.
setInterval(() => {}, 1 << 30)
