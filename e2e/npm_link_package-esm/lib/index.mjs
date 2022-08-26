import packageJson from './package.json';

export const id = () =>
        `${packageJson.name}@${
            packageJson.version ? packageJson.version : '0.0.0'
        }`
