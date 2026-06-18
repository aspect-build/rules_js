const lib = require('@lib/test')

const result = lib.id()
console.log('loaded:', result)

if (!result.includes('dist')) {
    throw new Error(
        'Expected to load from dist (via publishConfig.main) but got: ' + result
    )
}
