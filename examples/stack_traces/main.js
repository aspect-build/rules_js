const { a } = require('./lib/a')

try {
    a()
    throw new Error('a() should throw for this test')
} catch (e) {
    if (e.stack.indexOf('.runfiles/') !== -1) {
        throw new Error(
            'stacks.cjs should have stripped runfiles directories from the stack trace'
        )
    }
}
