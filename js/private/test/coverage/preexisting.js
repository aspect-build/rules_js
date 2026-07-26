// Reports its own coverage straight to COVERAGE_OUTPUT_FILE, the way a test program
// with its own lcov reporter (jest, nyc, ...) does. rules_js must not overwrite it
// with the c8 one. See https://github.com/aspect-build/rules_js/pull/430.
//
// Runs covered code too, so there is a c8 report to (wrongly) overwrite it with.
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

if (process.env.COVERAGE_OUTPUT_FILE) {
    require('fs').writeFileSync(
        process.env.COVERAGE_OUTPUT_FILE,
        '# reported by the test itself\n'
    )
}
