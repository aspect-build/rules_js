"Unit tests for test.bzl"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//js/private:pnpm_yaml.bzl", "parse_pnpm_lock")

def _parse_basic_test_impl(ctx):
    env = unittest.begin(ctx)

    # Scalar properties
    asserts.equals(env, {"foo": "bar"}, parse_pnpm_lock("foo: bar"))
    asserts.equals(env, {"foo": 1.5}, parse_pnpm_lock("foo: 1.5"))
    asserts.equals(env, {"foo": True}, parse_pnpm_lock("foo: true"))
    asserts.equals(env, {"foo": False}, parse_pnpm_lock("foo: false"))
    asserts.equals(env, {"foo": "bar:baz"}, parse_pnpm_lock("foo: bar:baz"))

    # Quoted keys
    asserts.equals(env, {"foo": "bar"}, parse_pnpm_lock("'foo': bar"))

    # Sequences
    asserts.equals(env, {"foo": ["bar"]}, parse_pnpm_lock("""\
foo:
    - bar
"""))
    asserts.equals(env, {"foo": ["bar", "baz"]}, parse_pnpm_lock("""\
foo: [bar, baz]
"""))

    # Multi-level maps
    asserts.equals(env, {"foo": {"moo": "cow"}}, parse_pnpm_lock("""\
foo:
    moo: cow
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse_pnpm_lock("""\
foo:
    bar:
        moo: 5
        cow: true
"""))
    asserts.equals(env, {"a": {"b": {"c": {"d": 1, "e": 2, "f": 3}, "g": {"h": 4}}}}, parse_pnpm_lock("""\
a:
  b:
    c:
        d: 1
        e: 2
        f: 3
    g:
        h: 4
"""))

    # More than one root property
    asserts.equals(env, {"a": True, "b": False}, parse_pnpm_lock("""\
a: true
b: false
"""))

    asserts.equals(env, {"a": {"b": True}, "c": {"d": False}}, parse_pnpm_lock("""\
a:
    b: true
c:
    d: false
"""))

    # Value begins on next line at an indent
    asserts.equals(env, {"moo": "cow"}, parse_pnpm_lock("""\
moo:
    cow
"""))

    # Object denoted with braces
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse_pnpm_lock("""\
foo: {bar: {moo: 5, cow: true}}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}, "baz": "faz"}}, parse_pnpm_lock("""\
foo: {bar: {moo: 5, cow: true}, baz: faz}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse_pnpm_lock("""\
foo:
    bar: {moo: 5, cow: true}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}, "baz": "faz"}}, parse_pnpm_lock("""\
foo:
    bar:
        {
            moo: 5, cow: true
        }
    baz:
        faz
"""))

    # Miscellaneous
    asserts.equals(env, {"foo": {"bar": "b-ar", "moo": ["cow"]}, "loo": ["roo", "goo"]}, parse_pnpm_lock("""\
foo:
    bar: b-ar
    moo: [cow]
loo:
    - roo
    - goo
"""))

    return unittest.end(env)

def _parse_lock_test_impl(ctx):
    env = unittest.begin(ctx)

    # Partial lock file
    asserts.equals(env, {
        "lockfileVersion": 5.4,
        "specifiers": {
            "@aspect-test/a": "5.0.0",
        },
        "dependencies": {
            "@aspect-test/a": "5.0.0",
        },
        "packages": {
            "/@aspect-test/a/5.0.0": {
                "resolution": {
                    "integrity": "sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==",
                },
                "hasBin": True,
                "dependencies": {
                    "@aspect-test/b": "5.0.0",
                    "@aspect-test/c": "1.0.0",
                    "@aspect-test/d": "2.0.0_@aspect-test+c@1.0.0",
                },
                "dev": False,
            },
        },
    }, parse_pnpm_lock("""\
lockfileVersion: 5.4

specifiers:
  '@aspect-test/a': 5.0.0

dependencies:
  '@aspect-test/a': 5.0.0

packages:

  /@aspect-test/a/5.0.0:
    resolution: {integrity: sha512-t/lwpVXG/jmxTotGEsmjwuihC2Lvz/Iqt63o78SI3O5XallxtFp5j2WM2M6HwkFiii9I42KdlAF8B3plZMz0Fw==}
    hasBin: true
    dependencies:
        '@aspect-test/b': 5.0.0
        '@aspect-test/c': 1.0.0
        '@aspect-test/d': 2.0.0_@aspect-test+c@1.0.0
    dev: false
"""))

    asserts.equals(env, {
        "/mobx-react-lite/3.3.0_mobx@6.5.0+react@17.0.2": {
            "resolution": {
                "integrity": "sha512-U/kMSFtV/bNVgY01FuiGWpRkaQVHozBq5CEBZltFvPt4FcV111hEWkgwqVg9GPPZSEuEdV438PEz8mk8mKpYlA==",
            },
            "peerDependencies": {
                "mobx": "^6.1.0",
                "react": "^16.8.0 || ^17",
                "react-dom": "*",
                "react-native": "*",
            },
            "peerDependenciesMeta": {
                "react-dom": {
                    "optional": True,
                },
                "react-native": {
                    "optional": True,
                },
            },
            "dependencies": {
                "mobx": "6.5.0",
                "react": "17.0.2",
            },
            "dev": True,
        },
    }, parse_pnpm_lock("""\
/mobx-react-lite/3.3.0_mobx@6.5.0+react@17.0.2:
    resolution: {integrity: sha512-U/kMSFtV/bNVgY01FuiGWpRkaQVHozBq5CEBZltFvPt4FcV111hEWkgwqVg9GPPZSEuEdV438PEz8mk8mKpYlA==}
    peerDependencies:
      mobx: ^6.1.0
      react: ^16.8.0 || ^17
      react-dom: '*'
      react-native: '*'
    peerDependenciesMeta:
      react-dom:
        optional: true
      react-native:
        optional: true
    dependencies:
      mobx: 6.5.0
      react: 17.0.2
    dev: true
"""))

    return unittest.end(env)

parse_basic_test = unittest.make(
    _parse_basic_test_impl,
    attrs = {},
)
parse_lock_test = unittest.make(
    _parse_lock_test_impl,
    attrs = {},
)

def pnpm_yaml_tests(name):
    unittest.suite(name, parse_basic_test, parse_lock_test)
