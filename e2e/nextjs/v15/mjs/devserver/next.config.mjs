import { join } from 'node:path'

// next is resolved from the node_modules of the parent package, which is outside this directory.
// Turbopack only resolves within its root, so point the root at the workspace root in the sandbox,
// as a monorepo would.
/** @type {import('next').NextConfig} */
export default {
    reactStrictMode: true,
    outputFileTracingRoot: join(import.meta.dirname, '../../..'),
}
