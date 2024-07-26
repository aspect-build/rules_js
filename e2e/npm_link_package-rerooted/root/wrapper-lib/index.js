const subdir = require('./subdir')
const lib = require('@e2e/lib')
const pkg = require('@e2e/pkg')

module.exports = {
    id: () => 'wrapper-lib',
    subdirId: () => subdir.id(),
    libId: () => lib.id(),
    pkgId: () => pkg.id(),
}
