const lodashVersion = require('lodash/package.json').version
if (lodashVersion !== '4.0.0') {
    throw new Error(
        `lodash aliased to file: should be version 4.0.0, got ${lodashVersion}`
    )
}

const lodash41721Version = require('lodash-4.17.21/package.json').version
if (lodash41721Version !== '4.17.21') {
    throw new Error(
        `lodash-4.17.21 aliased to file: should be version 4.17.21, got ${lodash41721Version}`
    )
}

const lodash41721VendoredVersion =
    require('lodash-4.17.21-tar/package.json').version
if (lodash41721VendoredVersion !== '4.17.21') {
    throw new Error(
        `lodash-4.17.21-tar aliased to file: should be version 4.17.21, got ${lodash41721VendoredVersion}`
    )
}
