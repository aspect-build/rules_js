import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import json from '@rollup/plugin-json'
import ts from '@rollup/plugin-typescript'

/** @type {import("rollup").RollupOptions} */
export default {
    plugins: [resolve(), commonjs(), json(), ts()],
}
