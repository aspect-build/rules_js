"Example macro wrapping the mocha CLI"

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_to_bin")
load("@npm//example/mocha:package_json.bzl", "bin")

def mocha_test(name, args = [], data = [], env = {}, **kwargs):
    srcs = kwargs.pop("srcs", native.glob(["test*.js"]))
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
            "configFile=$(location //example/mocha:mocha_reporters.json)",
            native.package_name() + "/*test.js",
        ] + args,
        data = data + [
            "_%s_srcs" % name,
            "//example/mocha:mocha_reporters.json",
            "@npm//example/mocha-multi-reporters",
            "@npm//example/mocha-junit-reporter",
        ],
        env = dict(env, **{
            "MOCHA_FILE": "$$XML_OUTPUT_FILE",
        }),
        **kwargs
    )
