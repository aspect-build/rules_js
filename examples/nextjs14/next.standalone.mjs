import { join } from 'node:path'

const appDir = import.meta.dirname || dirname(fileURLToPath(import.meta.url))

// Must include the parent .aspect_rules_js package store when tracing for standalone output
const outputFileTracingRoot = join(appDir, '../../')

/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,

    // Bundle everything into a standalone output
    output: 'standalone',
    outputFileTracingRoot,
}

export default nextConfig
