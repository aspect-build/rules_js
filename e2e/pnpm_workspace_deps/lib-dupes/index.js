// Two versions of the same package referenced throught aliases, see https://github.com/aspect-build/rules_js/issues/1110
module.exports = {
    importDep: () => require('@aspect-test/c'),
    importDupeDep: () => require('@aspect-test/c1'),
}
