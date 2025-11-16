// Crash if prod deps missing
require('debug');
require('is-odd'); 
require('semver');

// Crash if dev deps present (filtering failed)
try {
  require('@rollup/plugin-commonjs');
  throw new Error('DEV DEPENDENCY LEAKED INTO PROD BUILD');
} catch (e) {
  if (e.code !== 'MODULE_NOT_FOUND') throw e;
}

console.log('✅ Production filtering validated');