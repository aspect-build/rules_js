// A stand-in for the `next` CLI used by analysis-phase tests, which only inspect
// the generated action and never execute it.
console.error('fake next:', process.argv.slice(2).join(' '))
process.exit(1)
