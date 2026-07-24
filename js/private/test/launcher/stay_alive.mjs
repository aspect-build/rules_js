// Stays alive with no signal handlers installed, so a forwarded termination
// signal kills node outright. Paired with signal_exit_driver.mjs to verify the
// launcher surfaces node's signal death as exit code 128+N.
process.stdout.write('READY\n')

setInterval(() => {}, 1 << 30)
