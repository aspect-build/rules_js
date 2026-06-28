import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import json from '@rollup/plugin-json'
import terser from '@rollup/plugin-terser'

const plugins = [
    resolve({ preferBuiltins: true }),
    commonjs(),
    json(),
    terser({ format: { ascii_only: true } }),
]

/** @type {import("rollup").RollupOptions[]} */
export default [
    {
        input: 'pnpm_extract_catalogs.mjs',
        output: { file: 'pnpm_extract_catalogs.min.js', format: 'esm' },
        plugins,
    },
    {
        input: 'pnpm_package_json_transform.mjs',
        output: { file: 'pnpm_package_json_transform.min.js', format: 'esm', inlineDynamicImports: true },
        plugins,
    },
]
