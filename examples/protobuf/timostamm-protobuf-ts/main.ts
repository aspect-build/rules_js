import { LogMessage } from '../logger.ts'

let msg: LogMessage = {
    message: 'hello world',
}
const bytes = LogMessage.toBinary(msg)
msg = LogMessage.fromBinary(bytes)

console.log(JSON.stringify(msg))
