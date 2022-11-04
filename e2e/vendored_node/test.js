console.log(process.version)

if (process.version != 'v15.0.1') {
    console.error('Expected node version to be the one we vendored')
    process.exit(1)
}

console.log('All checked passed')
