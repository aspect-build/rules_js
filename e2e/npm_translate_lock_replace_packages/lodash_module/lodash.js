// Simple lodash replacement - version 4.17.20 equivalent
export default {
    uniq: function(array) {
        return [...new Set(array)];
    },
    version: "4.17.20"
};