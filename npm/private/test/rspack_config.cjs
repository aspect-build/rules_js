const { defineConfig } = require('@rspack/cli');
const path = require("path");

module.exports = defineConfig({
  entry: {
    main: './rspack_entry.js',
  },
  output: {
    path: path.resolve(process.cwd(), 'rspack/'),
    filename: '[name].bundle.js',
  },
});
