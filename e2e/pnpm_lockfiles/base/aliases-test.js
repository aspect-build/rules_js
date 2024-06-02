// `@aspect-test/{a,a2}` should be importable and equal
if (require('@aspect-test/a') !== require('@aspect-test/a2')) {
    throw new Error(
        'aliased `@aspect-test/a` as `@aspect-test/a2` are not the same'
    )
}

// `alias-types-node` and `@types/node` should be importable and equal
if (
    require('alias-types-node/package.json') !==
    require('@types/node/package.json')
) {
    throw new Error(
        'aliased `@types/node` as `alias-types-node` is not the same'
    )
}

// `is-odd` and the aliased `is-odd-alt-version` should be different versions
if (
    require('is-odd/package.json').version ===
    require('is-odd-alt-version/package.json').version
) {
    throw new Error('aliased `is-odd` as `is-odd-alt-version` are the same')
}

// `@isaacs/cliui` has transitive `npm:*` deps
require('@isaacs/cliui')
