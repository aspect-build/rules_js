const { join } = require('node:path')

const outputFileTracingRoot = join(__dirname, '../../')

/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    output: 'standalone',
    outputFileTracingRoot,
}

module.exports = nextConfig
