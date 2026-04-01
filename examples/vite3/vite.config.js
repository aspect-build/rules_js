// It makes no difference wether we use `require` or `import` statements here
const { defineConfig } = require('vite')
const react = require('@vitejs/plugin-react')

const defaultConfig = {
    optimizeDeps: {
        include: ['react/jsx-runtime'],
    },
    plugins: [react()],
    build: {
        outDir: 'build',
    },
    base: '/account/',
    resolve: {
        mainFields: ['browser', 'module', 'main'],
    },
}

export default defineConfig(({ command, mode }) => {
    if (command === 'serve' && mode === 'development') {
        return {
            ...defaultConfig,
            server: {
                host: '0.0.0.0',
            },
        }
    }

    return defaultConfig
})
