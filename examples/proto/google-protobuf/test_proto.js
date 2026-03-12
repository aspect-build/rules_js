import pkg from '../user_pb.js'
const { User } = pkg
import assert from 'node:assert'

let user = new User()
user.setName('hello world')
user = User.deserializeBinary(user.serializeBinary())
assert.equal(user.getName(), 'hello world')
