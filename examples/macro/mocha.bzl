"Example macro wrapping the mocha CLI"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_to_bin")
load("@npm//examples/macro/mocha:package_json.bzl", "bin")

def mocha_test(name, srcs, args = [], data = [], env = {}, **kwargs):
    copy_to_bin(
        name = "_%s_srcs" % name,
        srcs = srcs,
    )
    bin.mocha_test(
        name = name,
        args = [
            "--reporter",
            "mocha-multi-reporters",
            "--reporter-options",
            "configFile=$(location //examples/macro:mocha_reporters.json)",
            native.package_name() + "/*test.js",
        ] + args,
        data = data + [
            "_%s_srcs" % name,
            "//examples/macro:mocha_reporters.json",
            "@npm//examples/macro/mocha-multi-reporters",
            "@npm//examples/macro/mocha-junit-reporter",
        ],
        env = dict(env, **{
            # Add environment variable so that mocha writes its test xml
            # to the location Bazel expects.
            "MOCHA_FILE": "$$XML_OUTPUT_FILE",
        }),
        **kwargs
    )
