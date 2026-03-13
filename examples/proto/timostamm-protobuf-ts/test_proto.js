import { User } from '../user.js'
import assert from 'node:assert'

let user = User.create({
    name: 'hello world',
})

const bytes = User.toBinary(user)
user = User.fromBinary(bytes)
assert.equal(user.name, 'hello world')
