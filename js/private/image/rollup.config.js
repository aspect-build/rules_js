import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import ts from '@rollup/plugin-typescript'

/** @type {import("rollup").RollupOptions} */
export default {
    plugins: [
        resolve(),
        commonjs(),
        ts({
            target: 'es2022',
        }),
    ],
}
