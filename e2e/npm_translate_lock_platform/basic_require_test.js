// Basic test to verify esbuild can be required and works
// More comprehensive testing is done in test.sh

console.log('Testing basic esbuild functionality...');

try {
    const esbuild = require('esbuild');
    console.log('✅ esbuild loaded successfully, version:', esbuild.version);
    
    // Simple transform test
    const result = esbuild.transformSync('const x = 1', { format: 'esm' });
    console.log('✅ esbuild.transformSync works, result:', result.code);
} catch (error) {
    console.error('❌ Basic require test failed:', error.message);
    process.exit(1);
} 