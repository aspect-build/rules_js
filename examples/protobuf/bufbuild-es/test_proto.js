import { UserSchema } from './user_pb.js'
// The reason for this ugly import path is that //status:status_proto sets the
// strip_import_prefix attribute. Ideally strip_import_prefix (and
// import_prefix) should be avoided, but this example shows that it is possible
// to make it work if necessary.
import { StatusSchema } from './status/_virtual_imports/status_proto/status_pb.js'
import { create, fromBinary, toBinary } from '@bufbuild/protobuf'
import assert from 'node:assert'

let msg = create(UserSchema, {
    name: 'hello world',
    status: create(StatusSchema, { createdAt: new Date() }),
})

// Reference the inherited `.toBinary()` to ensure types from transitive types are included.
msg = fromBinary(UserSchema, toBinary(UserSchema, msg))

assert.equal(msg.name, 'hello world')
