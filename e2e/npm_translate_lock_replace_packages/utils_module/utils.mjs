// Utils module that depends on lodash
import lodash from 'lodash';

export function removeDuplicates(array) {
    return lodash.uniq(array);
}

export function getUtilsVersion() {
    return "1.0.0";
}

export function getLodashVersion() {
    return lodash.version;
}