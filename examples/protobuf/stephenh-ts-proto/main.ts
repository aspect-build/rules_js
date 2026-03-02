import { LogMessage } from '../logger.ts'

const bytes = LogMessage.encode({ message: 'hello world' }).finish()
const msg = LogMessage.decode(bytes)

console.log(JSON.stringify(LogMessage.toJSON(msg)))
