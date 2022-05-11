const packageJson = require('./package.json')
const aspect_f = require("@aspect-test/f") // expected to pass as lib/b has this dep
module.exports = {
    id: () =>
        `${packageJson.name}@${packageJson.version ? package.version : '0.0.0'
        }`,
    aspect_f: () =>
        `${aspect_f.name}@${aspect_f.version ? aspect_f.version : '0.0.0'
        }`,
}
