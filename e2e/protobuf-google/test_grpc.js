import grpc from '@grpc/grpc-js'
import assert from 'node:assert'
import messagesPkg from './greeter_pb.js'
import servicesPkg from './greeter_grpc_pb.js'

const { HelloRequest, HelloReply } = messagesPkg
const { GreeterService, GreeterClient } = servicesPkg

const server = new grpc.Server()
server.addService(GreeterService, {
    sayHello: (call, callback) => {
        const reply = new HelloReply()
        reply.setMessage(`Hello, ${call.request.getName()}!`)
        callback(null, reply)
    },
})

server.bindAsync(
    'localhost:0',
    grpc.ServerCredentials.createInsecure(),
    (err, port) => {
        if (err) throw err

        const client = new GreeterClient(
            `localhost:${port}`,
            grpc.credentials.createInsecure()
        )

        const request = new HelloRequest()
        request.setName('World')

        client.sayHello(request, (err, response) => {
            if (err) throw err
            assert.equal(response.getMessage(), 'Hello, World!')
            console.log(`Test passed: ${response.getMessage()}`)
            client.close()
            server.forceShutdown()
        })
    }
)
