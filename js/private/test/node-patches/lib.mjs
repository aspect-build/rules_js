import { fileURLToPath } from 'url'
import { dirname } from 'path'
import data from './data.json' with { type: 'json' }

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

export const my__dirname = __dirname
export const my__filename = __filename
export const my__pwd = process.cwd()

export const data2 = data
export const data3 = { ...data, addedKey: 'addedValue' }
