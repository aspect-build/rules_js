"Unit tests for yaml.bzl"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//js/private:yaml.bzl", "parse")

def _parse_basic_test_impl(ctx):
    env = unittest.begin(ctx)

    # Scalars
    asserts.equals(env, True, parse("true"))
    asserts.equals(env, False, parse("false"))
    asserts.equals(env, 1, parse("1"))
    asserts.equals(env, 3.14, parse("3.14"))
    asserts.equals(env, "foo", parse("foo"))
    asserts.equals(env, "foo", parse("'foo'"))
    asserts.equals(env, "foo", parse("\"foo\""))
    asserts.equals(env, "foo", parse("  foo"))
    asserts.equals(env, "foo", parse("  foo  "))
    asserts.equals(env, "foo", parse("foo  "))
    asserts.equals(env, "foo", parse("\nfoo"))
    asserts.equals(env, "foo", parse("foo\n"))
    asserts.equals(env, "-foo", parse("-foo"))
    asserts.equals(env, "foo{[]}", parse("foo{[]}"))

    # Sequences (- notation)
    asserts.equals(env, ["foo"], parse("- foo"))
    asserts.equals(env, ["foo - bar"], parse("- foo - bar"))
    asserts.equals(env, ["foo", "bar"], parse("""\
- foo
- bar
"""))
    asserts.equals(env, ["foo"], parse("""\
-
    foo
"""))
    asserts.equals(env, ["foo", "bar"], parse("""\
-
    foo
-
    bar
"""))
    asserts.equals(env, ["foo", "bar"], parse("""\
- foo
-
    bar
"""))

    # Sequences ([] notation)
    asserts.equals(env, [], parse("[]"))
    asserts.equals(env, ["foo"], parse("[foo]"))
    asserts.equals(env, ["fo o"], parse("[fo o]"))
    asserts.equals(env, ["fo\no"], parse("[fo\no]"))
    asserts.equals(env, ["foo", "bar"], parse("[foo,bar]"))
    asserts.equals(env, ["foo", "bar"], parse("[foo, bar]"))
    asserts.equals(env, [1, True, "false"], parse("[1, true, \"false\"]"))
    asserts.equals(env, ["foo", "bar"], parse("""\
[
    foo,
    bar
]
"""))
    asserts.equals(env, ["foo", "bar"], parse("""\
[
    foo,
    bar,
]
"""))
    asserts.equals(env, ["foo", "bar"], parse("""\
[
    'foo',
    "bar",
]
"""))
    asserts.equals(env, ["foo", "bar"], parse("""\
[
    foo,

    bar
]
"""))
    asserts.equals(env, [["foo", "bar"]], parse("[[foo,bar]]"))
    asserts.equals(env, [["foo", [1, True]]], parse("[[foo,[1, true]]]"))
    asserts.equals(env, [["foo", "bar"]], parse("[[foo, bar]]"))
    asserts.equals(env, [["foo", "bar"]], parse("""\
[
    [
        foo,
        bar
    ]
]
"""))

    # Maps - scalar properties
    asserts.equals(env, {"foo": "bar"}, parse("foo: bar"))
    asserts.equals(env, {"foo": "bar"}, parse("foo: 'bar'"))
    asserts.equals(env, {"foo": "bar"}, parse("foo: \"bar\""))
    asserts.equals(env, {"foo": "bar"}, parse("foo: bar  "))
    asserts.equals(env, {"foo": "bar"}, parse("'foo': bar"))
    asserts.equals(env, {"foo": "bar"}, parse("\"foo\": bar"))
    asserts.equals(env, {"foo": 1.5}, parse("foo: 1.5"))
    asserts.equals(env, {"foo": True}, parse("foo: true"))
    asserts.equals(env, {"foo": False}, parse("foo: false"))
    asserts.equals(env, {"foo": "bar:baz"}, parse("foo: bar:baz"))

    # Maps - flow notation
    asserts.equals(env, {}, parse("{}"))
    asserts.equals(env, {"foo": "bar"}, parse("{foo: bar}"))
    asserts.equals(env, {"foo": "bar"}, parse("{foo: 'bar'}"))
    asserts.equals(env, {"foo": "bar"}, parse("{foo: \"bar\"}"))
    asserts.equals(env, {"foo": "bar"}, parse("{foo: bar  }"))
    asserts.equals(env, {"foo": "bar"}, parse("{'foo': bar}"))
    asserts.equals(env, {"foo": "bar"}, parse("{\"foo\": bar}"))
    asserts.equals(env, {"foo": 1.5}, parse("{foo: 1.5}"))
    asserts.equals(env, {"foo": True}, parse("{foo: true}"))
    asserts.equals(env, {"foo": False}, parse("{foo: false}"))
    asserts.equals(env, {"foo": "bar:baz"}, parse("{foo: bar:baz}"))
    asserts.equals(env, {"foo": {"bar": 5}}, parse("{foo: {bar: 5}}"))
    asserts.equals(env, {"foo": 5, "bar": 6}, parse("{foo: 5, bar: 6}"))
    asserts.equals(env, {"foo": 5, "bar": {"moo": "cow"}, "faz": "baz"}, parse("{foo: 5, bar: {moo: cow}, faz: baz}"))
    asserts.equals(env, {"foo": {"bar": 5}}, parse("""\
{
    foo:
        {
            bar: 5
        }
}
"""))

    # Mixed sequence and map flows
    asserts.equals(env, {"foo": ["moo"]}, parse("{foo: [moo]}"))
    asserts.equals(env, ["foo", {"moo": "cow"}], parse("[foo, {moo: cow}]"))
    asserts.equals(env, {"foo": {"moo": "cow", "faz": ["baz", 123]}}, parse("{foo: {moo: cow, faz: [baz, 123]}}"))
    asserts.equals(env, [{"foo": ["bar", {"moo": ["cow"]}], "json": "bearded"}], parse("[{foo: [bar, {moo: [cow]}], json: bearded}]"))

    # Multi-level maps
    asserts.equals(env, {"foo": {"moo": "cow"}}, parse("""\
foo:
    moo: cow
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse("""\
foo:
    bar:
        moo: 5
        cow: true
"""))
    asserts.equals(env, {"a": {"b": {"c": {"d": 1, "e": 2, "f": 3}, "g": {"h": 4}}}}, parse("""\
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
    asserts.equals(env, {"a": True, "b": False}, parse("""\
a: true
b: false
"""))
    asserts.equals(env, {"a": {"b": True}, "c": {"d": False}}, parse("""\
a:
    b: true
c:
    d: false
"""))

    # Value begins on next line at an indent
    asserts.equals(env, {"moo": "cow"}, parse("""\
moo:
    cow
"""))

    # Mixed flow and non-flow maps
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse("""\
foo: {bar: {moo: 5, cow: true}}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}, "baz": "faz"}}, parse("""\
foo: {bar: {moo: 5, cow: true}, baz: faz}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}}}, parse("""\
foo:
    bar: {moo: 5, cow: true}
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": 5, "cow": True}, "baz": "faz"}, "json": ["bearded"]}, parse("""\
foo:
    bar:
        {
            moo: 5, cow: true
        }
    baz:
        faz
json: [bearded]
"""))
    asserts.equals(env, {"foo": {"bar": {"moo": [{"cow": True}]}}}, parse("""\
foo:
    bar: {moo: [
            {cow: true}
        ]}
"""))

    # Miscellaneous
    asserts.equals(env, {"foo": {"bar": "b-ar", "moo": ["cow"]}, "loo": ["roo", "goo"]}, parse("""\
foo:
    bar: b-ar
    moo: [cow]
loo:
    - roo
    - goo
"""))

    return unittest.end(env)

def _parse_lockfile_test_impl(ctx):
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
    }, parse("""\
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

    return unittest.end(env)

parse_basic_test = unittest.make(
    _parse_basic_test_impl,
    attrs = {},
)
parse_lockfile_test = unittest.make(
    _parse_lockfile_test_impl,
    attrs = {},
)

def yaml_tests(name):
    unittest.suite(name, parse_basic_test, parse_lockfile_test)
