const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')

module.exports = {
    mode: 'development',
    entry: './src/index.js',
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: './src/index.html',
            inject: false,
            // inject avoids the double load problem
            //https://stackoverflow.com/questions/37081559/all-my-code-runs-twice-when-compiled-by-webpack
        }),
    ],
}
