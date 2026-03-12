import { UserSchema } from '../user_pb.js'
import { StatusSchema } from '../status_pb.js'
import { create, fromBinary, toBinary } from '@bufbuild/protobuf'
import assert from 'node:assert'

let msg = create(UserSchema, {
    name: 'hello world',
    status: create(StatusSchema, { createdAt: new Date() }),
})

// Reference the inherited `.toBinary()` to ensure types from transitive types are included.
msg = fromBinary(UserSchema, toBinary(UserSchema, msg))

assert.equal(msg.name, 'hello world')
