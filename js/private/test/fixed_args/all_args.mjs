// Prints every argument, one per line, so a test can assert on how a fixed_arg was split.
for (const arg of process.argv.slice(2)) {
    console.log(`[${arg}]`)
}
