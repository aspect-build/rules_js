// Fails with a stack several frames deep, so that a test can tell node's own uncaught-exception
// report apart from a launcher that intercepted it.
function inner() {
    throw new Error('THROWN_FROM_PROGRAM')
}

function outer() {
    inner()
}

outer()
