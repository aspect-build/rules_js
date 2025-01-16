module.exports.a = function a() {
    return b()
}

function b() {
    throw new Error('the error')
}
