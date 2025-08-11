import lodash from 'lodash'

// In package.json, lodash is declared as a dependency with version 4.17.21
// but it should be replaced with version 4.17.20 in the final build.
if (lodash.version !== '4.17.20') {
    throw new Error(`Expected lodash version 4.17.20, but got ${lodash.version}`);
}