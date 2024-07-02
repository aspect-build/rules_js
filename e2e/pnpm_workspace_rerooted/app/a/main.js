// NOTE: keep in sync with e2e/pnpm_workspace(_rerooted)

console.log(process.argv)
console.log('--@aspect-test/a--', require('@aspect-test/a').id())
console.log('--@aspect-test/b--', require('@aspect-test/b').id())
console.log('--@aspect-test/c--', require('@aspect-test/c').id())
console.log('--@aspect-test/g--', require('@aspect-test/g').id())
console.log('--@lib/a--', require('@lib/a').id())
console.log('--@lib/a--', require('@lib/a').test())
