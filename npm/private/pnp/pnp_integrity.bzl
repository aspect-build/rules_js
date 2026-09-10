"""Validation helpers for the checked-in Yarn PnP integrity manifest."""

_REQUIRED_FILES = [
    ".pnp.cjs",
    ".pnp.data.json",
    ".yarnrc.yml",
    "yarn.lock",
]

def _is_lower_hex(value):
    if type(value) != "string" or len(value) != 128:
        return False
    for char in value.elems():
        if char not in "0123456789abcdef":
            return False
    return True

def _is_normalized_relative(path):
    if type(path) != "string" or not path or path.startswith("/") or path.endswith("/") or "\\" in path:
        return False
    if len(path) > 1 and path[1] == ":":
        return False
    for segment in path.split("/"):
        if segment in ["", ".", ".."]:
            return False
    return True

def _parse(content):
    data = json.decode(content)
    errors = []
    if type(data) != "dict":
        return struct(errors = ["integrity manifest must contain a JSON object"], files = {})
    if data.get("version", None) != 1:
        errors.append("integrity manifest version must be 1")
    files = data.get("files", None)
    if type(files) != "dict":
        return struct(errors = errors + ["integrity manifest files must be a JSON object"], files = {})

    normalized = {}
    for path in sorted(files.keys()):
        entry = files[path]
        if not _is_normalized_relative(path):
            errors.append("integrity manifest path must be normalized and project-relative: {}".format(path))
            continue
        if type(entry) != "dict" or entry.get("type", None) != "file" or not _is_lower_hex(entry.get("sha512", None)) or type(entry.get("executable", None)) != "bool":
            errors.append("integrity manifest entry for {} must contain type=file, a 128-character lowercase sha512, and executable=true|false".format(path))
            continue
        normalized[path] = entry

    for path in _REQUIRED_FILES:
        if path not in normalized:
            errors.append("integrity manifest is missing {}".format(path))

    return struct(errors = errors, files = normalized)

def _binding_errors(pnp_cjs_content, pnp_cjs, pnp_data, pnp_integrity, yarn_lock, yarnrc):
    errors = []
    labels = [pnp_cjs, pnp_data, pnp_integrity, yarn_lock, yarnrc]
    expected_names = [".pnp.cjs", ".pnp.data.json", ".pnp.integrity.json", "yarn.lock", ".yarnrc.yml"]
    expected_workspace = pnp_data.workspace_name
    expected_package = pnp_data.package
    for index in range(len(labels)):
        label = labels[index]
        if label.workspace_name != expected_workspace or label.package != expected_package:
            errors.append("{} must be in the same Bazel package as .pnp.data.json".format(label))
        if label.name != expected_names[index]:
            errors.append("{} must be named {} because the Yarn resolver uses canonical sibling paths".format(label, expected_names[index]))

    double_quoted = 'path.resolve(__dirname, ".pnp.data.json")'
    single_quoted = "path.resolve(__dirname, '.pnp.data.json')"
    if double_quoted not in pnp_cjs_content and single_quoted not in pnp_cjs_content:
        errors.append(".pnp.cjs does not bind to the sibling .pnp.data.json generated with pnpEnableInlining: false")
    return errors

pnp_integrity = struct(
    binding_errors = _binding_errors,
    parse = _parse,
)
