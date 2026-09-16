// Reports SIGINT without exiting and exits on SIGTERM, so that
// signal_sequence_driver.mjs can check the launcher still forwards a second,
// different signal after it has forwarded the first.
process.on('SIGINT', () => process.stdout.write('GOT_INT\n'))

process.on('SIGTERM', () => {
    // Exit from the write callback so the marker is flushed to the stdout pipe
    // before the process terminates.
    process.stdout.write('HANDLED\n', () => process.exit(0))
})

process.stdout.write('READY\n')

// Keep the event loop alive so the process does not exit on its own.
setInterval(() => {}, 1 << 30)
