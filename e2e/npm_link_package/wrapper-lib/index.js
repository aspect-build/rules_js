const subdir = require('./subdir')
const lib = require('@e2e/lib')

module.exports = {
    id: () => 'wrapper-lib',
    subdirId: () => subdir.id(),
    libId: () => lib.id(),
}
