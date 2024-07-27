import packageJson from './package.json'
import chalk from 'chalk'
export function name() {
    return chalk.blue(packageJson.name)
}
