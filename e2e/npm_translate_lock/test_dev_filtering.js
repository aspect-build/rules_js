// Crash if dev deps missing
require('@rollup/plugin-commonjs');
require('@rollup/plugin-json');
require('@rollup/plugin-node-resolve');

// Crash if prod deps present (filtering failed)
try {
  require('debug');
  throw new Error('PROD DEPENDENCY LEAKED INTO DEV BUILD');
} catch (e) {
  if (e.code !== 'MODULE_NOT_FOUND') throw e;
}

console.log('✅ Development filtering validated');