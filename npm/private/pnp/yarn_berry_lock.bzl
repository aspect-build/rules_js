"""Parser for Yarn Berry (v2+) yarn.lock files.

The lockfile is machine-generated YAML restricted to a small, stable subset:
nested string-keyed maps indented by 2 spaces with scalar leaf values. This
parser handles exactly that subset and fails loudly on anything else rather
than guessing.
"""

# Lockfile format versions this parser has been validated against.
# Version 6 is emitted by Yarn 3.x. Yarn 4 originally emitted version 8 and
# switched to version 10 in 4.18. Version 10 commonly keys entries by their
# resolved locator rather than retaining every requesting descriptor, so
# callers must not assume `descriptors` is complete for that format.
_SUPPORTED_METADATA_VERSIONS = ["6", "8", "10"]

_INDENT = 2

def _unquote(value):
    if len(value) >= 2 and value.startswith("\"") and value.endswith("\""):
        return value[1:-1]
    return value

def _parse_yaml_subset(content):
    """Parse the restricted YAML subset used by Berry lockfiles into nested dicts."""
    root = {}

    # Stack of (child_indent, dict) frames; leaf assignment targets the frame
    # whose child_indent matches the line's indentation.
    stack = [(0, root)]

    for lineno, line in enumerate(content.split("\n")):
        stripped = line.strip()
        if stripped == "" or stripped.startswith("#"):
            continue

        indent = len(line) - len(line.lstrip(" "))
        if indent % _INDENT != 0:
            fail("yarn.lock line {}: indentation is not a multiple of {}: {}".format(lineno + 1, _INDENT, line))

        for _ in range(len(stack)):
            if indent < stack[-1][0]:
                stack.pop()
        if indent != stack[-1][0]:
            fail("yarn.lock line {}: unexpected indentation: {}".format(lineno + 1, line))

        parent = stack[-1][1]

        if stripped.endswith(":"):
            # Opens a nested map.
            key = _unquote(stripped[:-1])
            child = {}
            parent[key] = child
            stack.append((indent + _INDENT, child))
            continue

        colon = stripped.find(": ")
        if colon == -1:
            fail("yarn.lock line {}: expected 'key: value' or 'key:': {}".format(lineno + 1, line))
        key = _unquote(stripped[:colon])
        parent[key] = _unquote(stripped[colon + 2:])

    return root

def _parse(content):
    """Parse a Yarn Berry yarn.lock file.

    Args:
        content: string content of the yarn.lock file

    Returns:
        struct with fields:
            metadata: dict of the `__metadata` block (version, cacheKey)
            entries: dict keyed by resolution locator (e.g. `left-pad@npm:1.3.0`),
                each value the entry's field dict (version, resolution, checksum,
                languageName, linkType, dependencies, ...)
            descriptors: dict mapping each descriptor (e.g. `left-pad@npm:^1.3.0`)
                to its resolution locator
    """
    root = _parse_yaml_subset(content)

    metadata = root.get("__metadata", None)
    if metadata == None:
        fail("yarn.lock has no __metadata block; only Yarn Berry lockfiles are supported")
    version = metadata.get("version", "")
    if version not in _SUPPORTED_METADATA_VERSIONS:
        fail("yarn.lock metadata version {} is not supported (supported: {})".format(version, ", ".join(_SUPPORTED_METADATA_VERSIONS)))

    entries = {}
    descriptors = {}
    for key, entry in root.items():
        if key == "__metadata":
            continue
        if type(entry) != "dict":
            fail("yarn.lock entry {} is not a map".format(key))
        resolution = entry.get("resolution", None)
        if resolution == None:
            fail("yarn.lock entry {} has no resolution".format(key))
        if resolution in entries:
            fail("yarn.lock has duplicate resolution {}".format(resolution))
        entries[resolution] = entry
        for descriptor in key.split(", "):
            if descriptor in descriptors:
                fail("yarn.lock has duplicate descriptor {}".format(descriptor))
            descriptors[descriptor] = resolution

    return struct(
        metadata = metadata,
        entries = entries,
        descriptors = descriptors,
    )

yarn_berry_lock = struct(
    parse = _parse,
)
