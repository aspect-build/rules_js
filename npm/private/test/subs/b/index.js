require('./package.json')

try {
    require('lodash')
    require('@subs/a')

    // It should throw before this line because this directory is not
    // a propper pnpm workspace project so no node_modules/ exist
    process.exit(1)
} catch {
    process.exit(0)
}
