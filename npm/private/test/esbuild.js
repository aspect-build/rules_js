// A simple wrapper around esbuild accepting 1 input file and 2 output file argument.

const [, , input, output] = process.argv

console.error('[ESBUILD] ', input, ' -> ', output)

require('esbuild')
    .build({
        entryPoints: [input],
        outfile: output,
        bundle: true,
        platform: 'node',
        target: 'node14',
    })
    .catch(() => process.exit(1))
