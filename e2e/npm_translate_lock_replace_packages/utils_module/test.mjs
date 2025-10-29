import { getLodashVersion, removeDuplicates } from './utils.mjs'

// Test that lodash is replaced with version 4.17.20
const version = getLodashVersion();
if (version !== '4.17.20') {
    throw new Error(`[utils_module] Expected lodash version 4.17.20, but got ${version}`);
}

const testArray = [1, 2, 2, 3, 3, 3];
const uniqueArray = removeDuplicates(testArray);
if (uniqueArray.length !== 3) {
    throw new Error(`[utils_module] Expected removeDuplicates to return 3 unique items, but got ${uniqueArray.length}`);
}

console.log('[utils_module] All tests passed ✓');