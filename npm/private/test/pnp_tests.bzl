"Unit tests for Yarn PnP zero-install lock, graph, and integrity validation"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private/pnp:pnp_data.bzl", "pnp_data")
load("//npm/private/pnp:pnp_integrity.bzl", "pnp_integrity")
load("//npm/private/pnp:yarn_berry_lock.bzl", "yarn_berry_lock")

_BERRY_LOCK = """\
__metadata:
  version: 8
  cacheKey: 10c0

"is-number@npm:^6.0.0":
  version: 6.0.0
  resolution: "is-number@npm:6.0.0"
  checksum: 10c0/{is_number_checksum}
  languageName: node
  linkType: hard

"is-odd@npm:3.0.1":
  version: 3.0.1
  resolution: "is-odd@npm:3.0.1"
  dependencies:
    is-number: "npm:^6.0.0"
  checksum: 10c0/{is_odd_checksum}
  languageName: node
  linkType: hard

"lodash@npm:^4.0.0, lodash@npm:^4.17.21":
  version: 4.17.21
  resolution: "lodash@npm:4.17.21"
  checksum: 10c0/{lodash_checksum}
  languageName: node
  linkType: hard

"fixture@workspace:.":
  version: 0.0.0-use.local
  resolution: "fixture@workspace:."
  dependencies:
    is-odd: "npm:3.0.1"
  languageName: unknown
  linkType: soft
""".format(
    is_number_checksum = "a" * 128,
    is_odd_checksum = "b" * 128,
    lodash_checksum = "c" * 128,
)

_PNP_DATA = """\
{
  "dependencyTreeRoots": [{"name": "fixture", "reference": "workspace:."}],
  "enableTopLevelFallback": true,
  "fallbackExclusionList": [["fixture", ["workspace:."]]],
  "fallbackPool": [],
  "ignorePatternData": null,
  "pnpZipBackend": "libzip",
  "packageRegistryData": [
    [null, [[null, {
      "packageLocation": "./",
      "packageDependencies": [["is-odd", "npm:3.0.1"], ["fixture", "workspace:."]],
      "linkType": "SOFT"
    }]]],
    ["fixture", [["workspace:.", {
      "packageLocation": "./",
      "packageDependencies": [["is-odd", "npm:3.0.1"], ["fixture", "workspace:."]],
      "linkType": "SOFT"
    }]]],
    ["is-odd", [["npm:3.0.1", {
      "packageLocation": "./.yarn/cache/is-odd-npm-3.0.1-93c3c3f41b-89ee2e353c.zip/node_modules/is-odd/",
      "packageDependencies": [["is-number", "npm:6.0.0"], ["is-odd", "npm:3.0.1"]],
      "linkType": "HARD"
    }]]],
    ["is-number", [["npm:6.0.0", {
      "packageLocation": "./.yarn/cache/is-number-npm-6.0.0-30881e83e6-5da4c68401.zip/node_modules/is-number/",
      "packageDependencies": [["is-number", "npm:6.0.0"]],
      "linkType": "HARD"
    }]]]
  ]
}
"""

def _parse_lock_test_impl(ctx):
    env = unittest.begin(ctx)
    lock = yarn_berry_lock.parse(_BERRY_LOCK)

    asserts.equals(env, "8", lock.metadata["version"])
    asserts.equals(env, "10c0/" + "b" * 128, lock.entries["is-odd@npm:3.0.1"]["checksum"])
    asserts.equals(env, "is-number@npm:6.0.0", lock.descriptors["is-number@npm:^6.0.0"])
    asserts.equals(env, "lodash@npm:4.17.21", lock.descriptors["lodash@npm:^4.0.0"])
    asserts.equals(env, "lodash@npm:4.17.21", lock.descriptors["lodash@npm:^4.17.21"])
    return unittest.end(env)

def _parse_yarn3_lock_test_impl(ctx):
    env = unittest.begin(ctx)
    yarn3_lock = _BERRY_LOCK.replace("version: 8", "version: 6").replace("10c0/", "")
    validated = pnp_data.validate(pnp_data.parse(_PNP_DATA), yarn3_lock)

    asserts.equals(env, "6", yarn_berry_lock.parse(yarn3_lock).metadata["version"])
    asserts.equals(env, [], validated.errors)
    asserts.equals(env, [
        "is-number-npm-6.0.0-30881e83e6-5da4c68401.zip",
        "is-odd-npm-3.0.1-93c3c3f41b-89ee2e353c.zip",
    ], validated.cache_zips)
    return unittest.end(env)

def _parse_yarn4_v10_real_shapes_test_impl(ctx):
    env = unittest.begin(ctx)
    lock = """\
__metadata:
  version: 10
  cacheKey: 10c0

"fixture@workspace:.":
  version: 0.0.0-use.local
  resolution: "fixture@workspace:."
  dependencies:
    has-peer: "npm:1.0.0"
    left-pad: "npm:1.3.0"
    peer: "npm:2.0.0"
  languageName: unknown
  linkType: soft

"has-peer@npm:1.0.0":
  version: 1.0.0
  resolution: "has-peer@npm:1.0.0"
  dependencies:
    left-pad: "npm:1.3.0"
  peerDependencies:
    peer: "^2.0.0"
  checksum: 10c0/{has_peer_checksum}
  languageName: node
  linkType: hard

"left-pad@npm:1.3.0":
  version: 1.3.0
  resolution: "left-pad@npm:1.3.0"
  checksum: 10c0/{left_pad_checksum}
  languageName: node
  linkType: hard

"peer@npm:2.0.0":
  version: 2.0.0
  resolution: "peer@npm:2.0.0"
  checksum: 10c0/{peer_checksum}
  languageName: node
  linkType: hard
""".format(
        has_peer_checksum = "d" * 128,
        left_pad_checksum = "e" * 128,
        peer_checksum = "f" * 128,
    )
    data = """\
{
  "dependencyTreeRoots": [{"name": "fixture", "reference": "workspace:."}],
  "enableTopLevelFallback": true,
  "fallbackExclusionList": [["fixture", ["workspace:."]]],
  "fallbackPool": [],
  "ignorePatternData": null,
  "pnpZipBackend": "libzip",
  "packageRegistryData": [
    [null, [[null, {"packageLocation": "./", "packageDependencies": [["fixture", "workspace:."], ["has-peer", "virtual:abc#npm:1.0.0"], ["left-pad", "npm:1.3.0"], ["peer", "npm:2.0.0"]], "linkType": "SOFT"}]]],
    ["fixture", [["workspace:.", {"packageLocation": "./", "packageDependencies": [["fixture", "workspace:."], ["has-peer", "virtual:abc#npm:1.0.0"], ["left-pad", "npm:1.3.0"], ["peer", "npm:2.0.0"]], "linkType": "SOFT"}]]],
    ["has-peer", [
      ["npm:1.0.0", {"packageLocation": "./.yarn/cache/has-peer-npm-1.0.0.zip/node_modules/has-peer/", "packageDependencies": [["has-peer", "npm:1.0.0"]], "linkType": "SOFT"}],
      ["virtual:abc#npm:1.0.0", {"packageLocation": "./.yarn/__virtual__/has-peer-virtual-abc/0/cache/has-peer-npm-1.0.0.zip/node_modules/has-peer/", "packageDependencies": [["has-peer", "virtual:abc#npm:1.0.0"], ["left-pad", "npm:1.3.0"], ["peer", "npm:2.0.0"]], "packagePeers": ["peer"], "linkType": "HARD"}]
    ]],
    ["left-pad", [["npm:1.3.0", {"packageLocation": "./.yarn/unplugged/left-pad-npm-1.3.0/node_modules/left-pad/", "packageDependencies": [["left-pad", "npm:1.3.0"]], "linkType": "HARD"}]]],
    ["peer", [["npm:2.0.0", {"packageLocation": "./.yarn/cache/peer-npm-2.0.0.zip/node_modules/peer/", "packageDependencies": [["peer", "npm:2.0.0"]], "linkType": "HARD"}]]]
  ]
}
"""
    validated = pnp_data.validate(pnp_data.parse(data), lock)

    asserts.equals(env, [], validated.errors)
    asserts.equals(env, [".yarn/unplugged/left-pad-npm-1.3.0"], validated.unplugged_roots)
    asserts.equals(env, "SOFT", validated.packages["has-peer@npm:1.0.0"]["link_type"])
    asserts.equals(env, "HARD", validated.packages["has-peer@virtual:abc#npm:1.0.0"]["link_type"])
    return unittest.end(env)

def _validate_test_impl(ctx):
    env = unittest.begin(ctx)
    validated = pnp_data.validate(pnp_data.parse(_PNP_DATA), _BERRY_LOCK)

    asserts.equals(env, [], validated.errors)
    asserts.equals(env, ["is-number@npm:6.0.0"], validated.packages["is-odd@npm:3.0.1"]["dependencies"])
    asserts.equals(env, None, validated.packages["fixture@workspace:."]["zip"])
    return unittest.end(env)

def _graph_mutation_test_impl(ctx):
    env = unittest.begin(ctx)
    decoded = json.decode(_PNP_DATA)
    decoded["packageRegistryData"][1][1][0][1]["packageDependencies"][0][1] = "npm:4.0.0"
    decoded["packageRegistryData"].append(["is-odd", [["npm:4.0.0", {
        "linkType": "HARD",
        "packageDependencies": [["is-odd", "npm:4.0.0"]],
        "packageLocation": "./.yarn/cache/is-odd-npm-4.0.0.zip/node_modules/is-odd/",
    }]]])
    lock = _BERRY_LOCK + """\

"is-odd@npm:4.0.0":
  version: 4.0.0
  resolution: "is-odd@npm:4.0.0"
  checksum: 10c0/{checksum}
  languageName: node
  linkType: hard
""".format(checksum = "d" * 128)
    errors = pnp_data.validate(pnp_data.parse(json.encode(decoded)), lock).errors

    asserts.true(env, any(["fixture@workspace:.: dependency is-odd resolves to is-odd@npm:4.0.0, expected is-odd@npm:3.0.1" in error for error in errors]))
    return unittest.end(env)

def _root_fallback_mutation_test_impl(ctx):
    env = unittest.begin(ctx)
    decoded = json.decode(_PNP_DATA)
    decoded["fallbackExclusionList"] = [["fixture", ["workspace:missing"]]]
    decoded["packageRegistryData"][0][1][0][1]["packageDependencies"] = [["fixture", "workspace:."]]
    errors = pnp_data.validate(pnp_data.parse(json.encode(decoded)), _BERRY_LOCK).errors

    asserts.true(env, any(["fallbackExclusionList" in error for error in errors]))
    asserts.true(env, any(["top-level fallback entry" in error for error in errors]))
    return unittest.end(env)

def _fallback_modes_test_impl(ctx):
    env = unittest.begin(ctx)
    none = json.decode(_PNP_DATA)
    none["enableTopLevelFallback"] = False
    none["fallbackExclusionList"] = []
    all_packages = json.decode(_PNP_DATA)
    all_packages["fallbackExclusionList"] = []

    asserts.equals(env, [], pnp_data.validate(pnp_data.parse(json.encode(none)), _BERRY_LOCK).errors)
    asserts.equals(env, [], pnp_data.validate(pnp_data.parse(json.encode(all_packages)), _BERRY_LOCK).errors)
    return unittest.end(env)

def _soft_non_template_edges_test_impl(ctx):
    env = unittest.begin(ctx)
    decoded = json.decode(_PNP_DATA)
    decoded["packageRegistryData"][2][1][0][1]["linkType"] = "SOFT"
    decoded["packageRegistryData"][2][1][0][1]["packageDependencies"] = [["is-odd", "npm:3.0.1"]]
    errors = pnp_data.validate(pnp_data.parse(json.encode(decoded)), _BERRY_LOCK).errors

    asserts.true(env, "is-odd@npm:3.0.1: lock dependency is-number@npm:^6.0.0 is missing from .pnp.data.json" in errors)
    asserts.true(env, "is-odd@npm:3.0.1: .pnp.data.json linkType SOFT does not match yarn.lock linkType HARD" in errors)
    return unittest.end(env)

def _top_level_shape_test_impl(ctx):
    env = unittest.begin(ctx)
    decoded = json.decode(_PNP_DATA)
    top_level_info = decoded["packageRegistryData"][0][1][0][1]
    decoded["packageRegistryData"].append([None, [[None, top_level_info]]])
    decoded["packageRegistryData"].append(["half-null", [[None, top_level_info]]])
    errors = pnp_data.validate(pnp_data.parse(json.encode(decoded)), _BERRY_LOCK).errors

    asserts.true(env, "packageRegistryData contains more than one [null, [[null, ...]]] top-level entry" in errors)
    asserts.true(env, "packageRegistryData contains a half-null package locator; name and reference must both be null only for the top-level entry" in errors)
    return unittest.end(env)

def _malformed_checksum_test_impl(ctx):
    env = unittest.begin(ctx)
    malformed = _BERRY_LOCK.replace("10c0/" + "a" * 128, "10c0/nothex")
    errors = pnp_data.validate(pnp_data.parse(_PNP_DATA), malformed).errors

    asserts.true(env, any(["yarn.lock checksum must be" in error and "nothex" in error for error in errors]))
    return unittest.end(env)

def _integrity_manifest_test_impl(ctx):
    env = unittest.begin(ctx)
    entry = {
        "executable": False,
        "sha512": "a" * 128,
        "type": "file",
    }
    manifest = pnp_integrity.parse(json.encode({
        "files": {
            ".pnp.cjs": entry,
            ".pnp.data.json": entry,
            ".yarnrc.yml": entry,
            "yarn.lock": entry,
        },
        "version": 1,
    }))
    corrupted = pnp_integrity.parse('{"version": 1, "files": {"..\\\\escape": "bad", "../escape": "bad"}}')

    asserts.equals(env, [], manifest.errors)
    asserts.true(env, len(corrupted.errors) >= 5)
    return unittest.end(env)

def _missing_lock_entry_test_impl(ctx):
    env = unittest.begin(ctx)
    decoded = json.decode(_PNP_DATA)
    decoded["packageRegistryData"].append(["ghost", [["npm:1.0.0", {
        "linkType": "HARD",
        "packageDependencies": [["ghost", "npm:1.0.0"]],
        "packageLocation": "./.yarn/cache/ghost.zip/node_modules/ghost/",
    }]]])
    errors = pnp_data.validate(pnp_data.parse(json.encode(decoded)), _BERRY_LOCK).errors

    asserts.true(env, "ghost@npm:1.0.0: present in .pnp.data.json but not in yarn.lock" in errors)
    return unittest.end(env)

parse_lock_test = unittest.make(_parse_lock_test_impl, attrs = {})
parse_yarn3_lock_test = unittest.make(_parse_yarn3_lock_test_impl, attrs = {})
parse_yarn4_v10_real_shapes_test = unittest.make(_parse_yarn4_v10_real_shapes_test_impl, attrs = {})
validate_test = unittest.make(_validate_test_impl, attrs = {})
graph_mutation_test = unittest.make(_graph_mutation_test_impl, attrs = {})
root_fallback_mutation_test = unittest.make(_root_fallback_mutation_test_impl, attrs = {})
integrity_manifest_test = unittest.make(_integrity_manifest_test_impl, attrs = {})
missing_lock_entry_test = unittest.make(_missing_lock_entry_test_impl, attrs = {})
fallback_modes_test = unittest.make(_fallback_modes_test_impl, attrs = {})
soft_non_template_edges_test = unittest.make(_soft_non_template_edges_test_impl, attrs = {})
top_level_shape_test = unittest.make(_top_level_shape_test_impl, attrs = {})
malformed_checksum_test = unittest.make(_malformed_checksum_test_impl, attrs = {})

TESTS = [
    parse_lock_test,
    parse_yarn3_lock_test,
    parse_yarn4_v10_real_shapes_test,
    validate_test,
    graph_mutation_test,
    root_fallback_mutation_test,
    fallback_modes_test,
    soft_non_template_edges_test,
    top_level_shape_test,
    malformed_checksum_test,
    integrity_manifest_test,
    missing_lock_entry_test,
]

def pnp_tests(name):
    for index, test_rule in enumerate(TESTS):
        test_rule(name = "{}_test_{}".format(name, index))
