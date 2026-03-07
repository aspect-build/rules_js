var logger_pb = require('../logger_pb.js')

let msg = new logger_pb.LogMessage()
msg.setMessage('hello world')
msg = logger_pb.LogMessage.deserializeBinary(msg.serializeBinary())

console.log(JSON.stringify(msg.toObject()))
