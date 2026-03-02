import { LogMessageSchema } from '../logger_pb.js'
import { create, fromBinary, toBinary } from '@bufbuild/protobuf'

let msg = create(LogMessageSchema, { message: 'hello world' })
msg = fromBinary(LogMessageSchema, toBinary(LogMessageSchema, msg))

console.log(JSON.stringify(msg))
