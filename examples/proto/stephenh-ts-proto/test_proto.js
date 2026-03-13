import { User } from '../user.ts'
import assert from 'node:assert'

const bytes = User.encode({ message: 'hello world' }).finish()
const user = User.decode(bytes)

assert.equal(user.name, 'hello world')
