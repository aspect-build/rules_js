/**
 * @fileoverview minimal test program that requires a third-party package from npm
 */
import { writeFileSync } from 'node:fs'
import { parse } from 'acorn'

writeFileSync(
    process.argv[2],
    JSON.stringify(parse('1', { ecmaVersion: 2020 })) + '\n'
)
