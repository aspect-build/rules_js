// `@aspect-test/{a,a2}` should be importable and equal
if (require('@aspect-test/a') !== require('@aspect-test/a2')) {
    throw new Error(
        'aliased `@aspect-test/a` as `@aspect-test/a2` are not the same'
    )
}

// Various other aliases with odd scoping
for (const pkg of [
    '@aspect-test/a2',
    'aspect-test-a-no-scope',
    'aspect-test-a/no-at',
    '@aspect-test-a-bad-scope',
    '@aspect-test-custom-scope/a',
]) {
    if (require('@aspect-test/a') !== require(pkg)) {
        throw new Error(`${pkg} should be alias of @aspect-test/a`)
    }
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

// `is-odd` and the aliased `is-odd-alias` should be different versions
if (
    require('is-odd/package.json').version !== '3.0.1' ||
    require('is-odd/package.json').version !==
        require('is-odd-alias/package.json').version
) {
    throw new Error('aliased `is-odd` as `is-odd-alias` should be the same')
}

if (
    require('is-odd-v0/package.json').version[0] !== '0' ||
    require('is-odd-v1/package.json').version[0] !== '1' ||
    require('is-odd-v2/package.json').version[0] !== '2' ||
    require('is-odd-v3/package.json').version[0] !== '3'
) {
    throw new Error('aliased `is-odd-v#` should have the correct version')
}

// `@isaacs/cliui` has transitive `npm:*` deps
require('@isaacs/cliui')

// `alias-only-sizzle` aliases a package not declared elsewhere
require('alias-only-sizzle/package.json')
