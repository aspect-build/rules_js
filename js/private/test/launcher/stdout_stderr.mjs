// Writes distinct markers to stdout and stderr so the launcher can be checked
// for passing each stream through separately rather than merging them.
process.stdout.write('ON_STDOUT\n')
process.stderr.write('ON_STDERR\n')
