import { join } from 'node:path'

// Must include the parent .aspect_rules_js package store when tracing for standalone output
const outputFileTracingRoot = join(import.meta.dirname, '../../')

/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,

    // Bundle everything into a standalone output
    output: 'standalone',
    outputFileTracingRoot,
    
    // If you're using NextJS 14, replace outputFileTracingRoot with:
    // experimental: {
    //   outputFileTracingRoot,
    // },
}

export default nextConfig
