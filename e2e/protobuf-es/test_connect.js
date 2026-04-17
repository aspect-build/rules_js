import { GetUserRequestSchema, UserSchema, UserService } from './user_pb.js'
import { createClient, createRouterTransport } from '@connectrpc/connect'
import { create } from '@bufbuild/protobuf'
import assert from 'node:assert'

// In protobuf-es v2, service descriptors are embedded in the _pb.js file
// alongside message schemas, so no separate codegen step is needed.
assert.ok(UserService, 'UserService should be defined')
assert.ok(UserService.method.getUser, 'getUser method should be defined')

const transport = createRouterTransport((router) => {
    router.service(UserService, {
        getUser(req) {
            return create(UserSchema, { name: req.name })
        },
    })
})

const client = createClient(UserService, transport)
const response = await client.getUser(
    create(GetUserRequestSchema, { name: 'alice' })
)
assert.equal(response.name, 'alice')
