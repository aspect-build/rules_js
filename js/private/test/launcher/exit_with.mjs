// Exits with the code given as the first argument (default 0). Paired with a
// js_binary expected_exit_code to exercise the launcher's exit-code remapping.
process.exit(Number(process.argv[2] ?? 0))
