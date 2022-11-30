import * as path from 'path'
import HtmlWebpackPlugin from 'html-webpack-plugin'

export default {
    mode: 'development',
    entry: './src/index.js',
    output: {
        filename: 'main.js',
        path: path.join(process.cwd(), 'dist'),
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
