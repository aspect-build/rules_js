// A passing test whose exit status is non-zero, matching the target's
// expected_exit_code. Coverage must still be generated for it: the exit hook in
// bootstrap.cjs compares the exit code against JS_BINARY__EXPECTED_EXIT_CODE, not
// against zero. See #2932.
if (true) {
    covered()
} else {
    uncovered()
}

function covered() {
    console.log('covered')
}

function uncovered() {
    console.log('uncovered')
}

process.exit(42)
