const path = require('path')

const out_path = path.resolve(__dirname, 'dist')

module.exports = (webpackEnv = {}) => {
    return {
        entry: path.join(__dirname, 'index.js'),
        // stats: 'verbose',
        mode: 'development',
        stats: 'detailed',
        output: {
            filename: 'main.js',
            path: out_path,
        },
    }
}
