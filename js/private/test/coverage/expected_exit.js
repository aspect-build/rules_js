// A passing test whose exit status is non-zero, matching the target's
// expected_exit_code. Coverage must still be generated for it.
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
