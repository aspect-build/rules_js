import path from 'node:path'

import {
    formatRunfilesSyncEvent,
    isNodeModulePath,
    is1pPackageStoreDep,
    friendlyFileSize,
    parseIBazelEvent,
} from '../../devserver/js_run_devserver.mjs'

// isNodeModulePath
const isNodeModulePath_true = [
    '/private/var/some/path/node_modules/@babel/core',
    '/private/var/some/path/node_modules/lodash',
]
for (const p of isNodeModulePath_true) {
    if (!isNodeModulePath(p)) {
        console.error(`ERROR: expected ${p} to be a node_modules path`)
        process.exit(1)
    }
}
const isNodeModulePath_false = ['/private/var/some/path/some-file.js']
for (const p of isNodeModulePath_false) {
    if (isNodeModulePath(p)) {
        console.error(`ERROR: expected ${p} to not be a node_modules path`)
        process.exit(1)
    }
}

// is1pPackageStoreDep
const is1pPackageStoreDep_true = [
    'some/path/node_modules/.aspect_rules_js/@mycorp+pkg@0.0.0/node_modules/@mycorp/pkg',
    'some/path/node_modules/.aspect_rules_js/mycorp-pkg@0.0.0/node_modules/mycorp-pkg',
]
for (const p of is1pPackageStoreDep_true) {
    if (!is1pPackageStoreDep(p)) {
        console.error(`ERROR: expected ${p} to be a 1p package store dep`)
        process.exit(1)
    }
}
const is1pPackageStoreDep_false = [
    'some/path/node_modules/.aspect_rules_js/@mycorp+pkg@0.0.0/node_modules/mycorp/pkg',
    'some/path/node_modules/.aspect_rules_js/@mycorp+pkg0.0.0/node_modules/@mycorp/pkg',
    'some/path/node_modules/.aspect_rules_js/mycorp+pkg@0.0.0/node_modules/@mycorp/pkg',
    'some/path/node_modules/.aspect_rules_js/mycorp-pkg0.0.0/node_modules/mycorp-pkg',
    'some/path/node_modules/.aspect_rules_js/@mycorp+pkg@0.0.0/node_modules/acorn',
    'some/path/node_modules/.aspect_rules_js/mycorp-pkg@0.0.0/node_modules/acorn',
    'some/path/node_modules/.aspect_rules_js/@babel+runtime@7.21.0/node_modules/@babel/runtime',
    'some/path/node_modules/.aspect_rules_js/@babel+runtime@7.21.0/node_modules/acorn',
    'some/path/node_modules/.aspect_rules_js/eval@0.1.6/node_modules/eval',
    'some/path/node_modules/.aspect_rules_js/eval@0.1.6/node_modules/acorn',
]
for (const p of is1pPackageStoreDep_false) {
    if (is1pPackageStoreDep(p)) {
        console.error(`ERROR: expected ${p} to not be a 1p package store dep`)
        process.exit(1)
    }
}

// friendlyFileSize
const friendlyFileSize_cases = new Map()
friendlyFileSize_cases.set(0, '0 B')
friendlyFileSize_cases.set(1, '1 B')
friendlyFileSize_cases.set(100, '100 B')
friendlyFileSize_cases.set(1023, '1023 B')
friendlyFileSize_cases.set(1024, '1.0 KiB')
friendlyFileSize_cases.set(1300, '1.3 KiB')
friendlyFileSize_cases.set(1024 * 1024, '1.0 MiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024, '1.0 GiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024 * 1024, '1.0 TiB')
friendlyFileSize_cases.set(1024 * 1024 * 1024 * 1024 * 1024, '1.0 PiB')
friendlyFileSize_cases.set(
    1024 * 1024 * 1024 * 1024 * 1024 * 1024,
    '1024.0 PiB'
)
for (const [k, v] of friendlyFileSize_cases) {
    const a = friendlyFileSize(k)
    if (a !== v) {
        console.error(
            `Expected friendlyFileSize(${k}) to be '${v}' but got '${a}'`
        )
        process.exit(1)
    }
}

// notify_changes_v1 post-sync event
const ibazelEvent = parseIBazelEvent(
    'IBAZEL_EVENT {"version":1,"type":"build_completed","success":true,"changes":[{"path":"/workspace/src/app.ts","kind":"source"}]}'
)
if (!ibazelEvent || !ibazelEvent.success) {
    console.error('ERROR: expected a valid successful iBazel event')
    process.exit(1)
}
if (parseIBazelEvent('IBAZEL_BUILD_COMPLETED SUCCESS') !== null) {
    console.error('ERROR: expected legacy notification to be ignored')
    process.exit(1)
}

const syncEventPrefix = 'JS_RUN_DEVSERVER_SYNCED '
const syncEvent = formatRunfilesSyncEvent(
    '/sandbox',
    [
        { file: 'b.js', exists: true },
        { file: 'a.js', exists: false },
    ],
    ['c.js'],
    ibazelEvent
)
if (!syncEvent.endsWith('\n')) {
    console.error('ERROR: expected runfiles sync event to end with a newline')
    process.exit(1)
}
const syncEventPayload = JSON.parse(syncEvent.slice(syncEventPrefix.length))
const expectedChanges = [
    { path: path.join('/sandbox', 'a.js'), kind: 'added' },
    { path: path.join('/sandbox', 'b.js'), kind: 'changed' },
    { path: path.join('/sandbox', 'c.js'), kind: 'deleted' },
]
if (JSON.stringify(syncEventPayload.changes) !== JSON.stringify(expectedChanges)) {
    console.error(
        `ERROR: expected runfiles changes ${JSON.stringify(
            expectedChanges
        )} but got ${JSON.stringify(syncEventPayload.changes)}`
    )
    process.exit(1)
}
if (JSON.stringify(syncEventPayload.trigger) !== JSON.stringify(ibazelEvent)) {
    console.error('ERROR: expected sync event to retain the parsed iBazel event')
    process.exit(1)
}
