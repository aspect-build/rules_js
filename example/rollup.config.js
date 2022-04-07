const commonjs = require('@rollup/plugin-commonjs')
const { nodeResolve: resolve } = require('@rollup/plugin-node-resolve')

module.exports = {
    plugins: [resolve(), commonjs()],
}
