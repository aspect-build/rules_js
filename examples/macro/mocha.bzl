"Example macro wrapping the mocha CLI"

load("@npm//examples/macro:mocha/package_json.bzl", "bin")

def mocha_test(name, srcs, args = [], data = [], env = {}, **kwargs):
    bin.mocha_test(
        name = name,
        args = [
            "--reporter",
            "mocha-multi-reporters",
            "--reporter-options",
            "configFile=$(rootpath //examples/macro:mocha_reporters.json)",
            native.package_name() + "/*test.*js",
        ] + args,
        data = data + srcs + [
            "//examples/macro:mocha_reporters.json",
            "//examples/macro:node_modules/mocha-multi-reporters",
            "//examples/macro:node_modules/mocha-junit-reporter",
        ],
        env = dict(env, **{
            # Add environment variable so that mocha writes its test xml
            # to the location Bazel expects.
            "MOCHA_FILE": "$$XML_OUTPUT_FILE",
        }),
        preserve_symlinks_main = False,
        copy_data_to_bin = False,
        **kwargs
    )
