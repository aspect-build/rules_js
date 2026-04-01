import { join } from 'node:path'

const outputFileTracingRoot = join(import.meta.dirname, '../../')

/** @type {import('next').NextConfig} */
export default {
    reactStrictMode: true,
    output: 'standalone',
    outputFileTracingRoot,
}
