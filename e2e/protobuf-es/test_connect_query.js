import { say } from './eliza-ElizaService_connectquery.js'
import { callUnaryMethod } from '@connectrpc/connect-query-core'
import { createRouterTransport } from '@connectrpc/connect'
import { create } from '@bufbuild/protobuf'
import assert from 'node:assert'

assert.ok(say, 'say should be defined')
assert.equal(say.name, 'Say')
assert.equal(say.methodKind, 'unary')

// Create a mock transport that implements the ElizaService by echoing back the input.
const transport = createRouterTransport((router) => {
    router.service(say.parent, {
        say(req) {
            return create(say.output, { sentence: `You said: ${req.sentence}` })
        },
    })
})

// Use callUnaryMethod from connect-query-core to invoke the RPC through the transport.
const response = await callUnaryMethod(transport, say, { sentence: 'hello' })
assert.equal(response.sentence, 'You said: hello')
