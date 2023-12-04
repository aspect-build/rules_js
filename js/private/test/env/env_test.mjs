// Many of these env variables are set by Bazel. See https://bazel.build/reference/test-encyclopedia#initial-conditions.
const expected = {
    BAZEL_TEST: '1',
    BAZEL: '1',
    JS_BINARY__BINDIR: /^bazel-out\/[a-z0-9\-]+\/bin$/,
    JS_BINARY__BUILD_FILE_PATH: 'js/private/test/env/BUILD.bazel',
    JS_BINARY__COMPILATION_MODE: /.+/,
    JS_BINARY__COPY_DATA_TO_BIN: '1',
    JS_BINARY__EXECROOT: /.+/,
    JS_BINARY__FS_PATCH_ROOTS: /.+/,
    JS_BINARY__LOG_ERROR: '1',
    JS_BINARY__LOG_FATAL: '1',
    JS_BINARY__LOG_PREFIX: 'aspect_rules_js[js_test]',
    JS_BINARY__NODE_BINARY: /bin\/nodejs\/bin\/node$/,
    JS_BINARY__NODE_PATCHES_DEPTH: '.',
    JS_BINARY__NODE_PATCHES:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test.sh.runfiles\/[a-z_]+\/js\/private\/node-patches\/register\.js$/,
    JS_BINARY__NODE_WRAPPER:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test.sh.runfiles\/[a-z_]+\/js\/private\/test\/env\/env_test_node_bin\/node$/,
    JS_BINARY__PACKAGE: 'js/private/test/env',
    JS_BINARY__PATCH_NODE_FS: '1',
    JS_BINARY__RUNFILES:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test\.sh\.runfiles$/,
    JS_BINARY__TARGET_CPU: /.+/,
    JS_BINARY__TARGET_NAME: 'env_test',
    JS_BINARY__TARGET: '//js/private/test/env:env_test',
    JS_BINARY__WORKSPACE: /[a-z_]+/,
    RUNFILES_DIR:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test\.sh\.runfiles$/,
    RUNFILES:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test\.sh\.runfiles$/,
    TEST_BINARY: 'js/private/test/env/env_test.sh',
    TEST_INFRASTRUCTURE_FAILURE_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.infrastructure_failure$/,
    TEST_LOGSPLITTER_OUTPUT_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.raw_splitlogs\/test\.splitlogs$/,
    TEST_PREMATURE_EXIT_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.exited_prematurely$/,
    TEST_SIZE: 'medium',
    TEST_SRCDIR:
        /bazel-out\/[a-z0-9\-]+\/bin\/js\/private\/test\/env\/env_test\.sh\.runfiles$/,
    TEST_TARGET: '//js/private/test/env:env_test',
    TEST_TIMEOUT: /[0-9]+/,
    TEST_TMPDIR: /.+/,
    TEST_UNDECLARED_OUTPUTS_ANNOTATIONS_DIR:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.outputs_manifest$/,
    TEST_UNDECLARED_OUTPUTS_DIR:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.outputs$/,
    TEST_UNUSED_RUNFILES_LOG_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.unused_runfiles_log$/,
    TEST_WARNINGS_OUTPUT_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.warnings$/,
    TEST_WORKSPACE: /[a-z_]+/,
    XML_OUTPUT_FILE:
        /bazel-out\/[a-z0-9\-]+\/testlogs\/js\/private\/test\/env\/env_test\/test\.xml$/,
}

let failed = false
for (const k of Object.keys(expected)) {
    const v = expected[k]
    if (typeof v === 'string') {
        if (process.env[k] !== v) {
            console.error(
                `Expected environment variable ${k} to equal '${v}' but got '${process.env[k]}' instead`
            )
            failed = true
        }
    } else {
        if (!process.env[k].match(v)) {
            console.error(
                `Expected environment variable ${k} to match regex ${v} but value '${process.env[k]}' does not match`
            )
            failed = true
        }
    }
}
if (failed) {
    process.exit(1)
}
