import { FooSchema } from './foo_pb.js'
import { create, fromBinary, toBinary } from '@bufbuild/protobuf'

let msg = create(FooSchema, { name: 'hello world' })

// Reference the inherited `.toBinary()` to ensure types from transitive types are included.
msg = fromBinary(FooSchema, toBinary(FooSchema, msg))

console.log(JSON.stringify(msg))
