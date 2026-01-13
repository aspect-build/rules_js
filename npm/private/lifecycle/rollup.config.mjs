import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import replace from '@rollup/plugin-replace'
import json from '@rollup/plugin-json'
import terser from '@rollup/plugin-terser'

/** @type {import("rollup").RollupOptions} */
export default {
    external: ['readable-stream'],
    plugins: [
        resolve({
            preferBuiltins: true,
        }),
        // https://github.com/rollup/rollup/issues/1507#issuecomment-340550539
        replace({
            preventAssignment: true,
            delimiters: ['', ''],
            values: {
                'readable-stream': 'stream',
            },
        }),
        commonjs(),
        json(),
        // ascii_only avoids bad unicode conversions, fixing
        // https://github.com/aspect-build/rules_js/issues/45
        terser({
            format: {
                ascii_only: true,
            },
        }),
    ],
    onwarn: (warning, defaultHandler) => {
        // warning but works, hide it. https://github.com/isaacs/node-glob/issues/365
        if (
            warning.code === 'CIRCULAR_DEPENDENCY' &&
            warning.message.includes('/glob/')
        ) {
            return
        }
        defaultHandler(warning)
    },
}
