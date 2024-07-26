export const id = () => 'wrapper-lib'
// NOTE: .mjs does not support index files unless it is alongside a package.json
// containing an `"exports": {".": "index.mjs"}`.
// See: https://nodejs.org/api/packages.html#exports
export { id as subdirId } from './subdir/index.mjs'
export { id as libId } from '@e2e/lib'
export { id as pkgId } from '@e2e/pkg'
