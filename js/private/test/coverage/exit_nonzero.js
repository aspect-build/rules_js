// Runs covered code, then exits non-zero. The test declares this code as its
// expected_exit_code, so it passes while its raw exit status is non-zero.
// Regression test that coverage is still generated in that case. See PR #2932.
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
