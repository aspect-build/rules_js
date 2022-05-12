"Parse pnpm lock files into starlark"

_STATE = struct(
    # Read a property key
    PROPERTY = 0,
    # Parse an object's value
    PARSE_VALUE = 1,
    # We parsed a value with a colon, double check that it's a property and not a string
    CONFIRM_PROPERTY = 2,
    # We are parsing a sequence
    PARSE_SEQUENCE = 3,
    PARSE_BRACKET_SEQUENCE = 4,
    # Handle cases after closing a curly brace
    AFTER_OBJECT_CLOSE = 5,
)

def parse_pnpm_lock(lockfile_content):
    """Parse a pnpm lock file.

    Args:
        lockfile_content: yaml lockfile content

    Returns:
        dict containing parsed lockfile
    """
    return _parse_yaml(lockfile_content)

def _parse_yaml(yaml):
    """Experimental yaml parser that only parses a subset of yaml needed by pnpm lock files."""
    result = {}
    stack = []
    stack.append({
        "id": _STATE.PROPERTY,
        "key": "",
        "indent": 0,
    })
    for input in (yaml + "\n").elems():
        state = _peek(stack)
        if state["id"] == _STATE.PROPERTY:
            if input == "\n":
                state["indent"] = 0
                pass
            elif input.isspace():
                state["indent"] += 1
            elif input == "}":
                stack.pop()
                stack.pop()

                # start scanning for the next key
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": _peek(stack)["indent"],
                })
            elif input != ":":
                state["key"] += input
            else:
                state["key"] = _normalize_key(state["key"])

                # Remove PROPERTY states with a lower indent
                stack = [s for s in stack if s == state or s["indent"] < state["indent"]]

                stack.append({
                    "id": _STATE.PARSE_VALUE,
                    "value_on_next_line": False,
                    "indent": 0,
                    "value": "",
                    "started": False,
                })
        elif state["id"] == _STATE.PARSE_VALUE:
            if input == "\n":
                if not state["value_on_next_line"] and state["value"] == "":
                    state["value_on_next_line"] = True
                elif state["value"] != "":
                    # We finished collecting a scalar
                    stack.pop()
                    property_state = stack.pop()

                    _get_current_object(result, stack)[property_state["key"]] = _parse_scalar(state["value"])
                    stack.append({
                        "id": _STATE.PROPERTY,
                        "key": "",
                        "indent": 0,
                    })
                else:
                    pass
            elif input.isspace():
                # Consume space after key on same line
                if not state["value_on_next_line"]:
                    if state["started"]:
                        state["value"] += input

                    # Being counting the indentation
                elif not state["started"]:
                    state["indent"] += 1

            elif input == "{":
                # We know it's an object, begin reading the next key
                stack.pop()
                property_state = _peek(stack)
                _get_current_object(result, stack[0:-1])[property_state["key"]] = {}
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": property_state["indent"] + 4,
                })
            elif input == "-" and state["value_on_next_line"]:
                stack.pop()
                stack.append({
                    "id": _STATE.PARSE_SEQUENCE,
                    "sequence": [],
                    "value": "",
                    "started": True,
                })
            elif input == "[" and state["value"] == "":
                stack.pop()
                stack.append({
                    "id": _STATE.PARSE_BRACKET_SEQUENCE,
                    "sequence": [],
                    "value": "",
                })
            elif input == ":":
                stack.append({
                    "id": _STATE.CONFIRM_PROPERTY,
                })
            elif input == ",":
                # We just parsed a scalar
                stack.pop()
                property_state = stack.pop()
                _get_current_object(result, stack)[property_state["key"]] = _parse_scalar(state["value"])
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": property_state["indent"],
                })
            elif input == "}":
                # We just closed an object
                stack.pop()

                # set the scalar if there's a value
                if state["value"] != "":
                    property_state = stack.pop()
                    _get_current_object(result, stack)[property_state["key"]] = _parse_scalar(state["value"])
                stack.append({
                    "id": _STATE.AFTER_OBJECT_CLOSE,
                })
            else:
                state["started"] = True
                state["value"] += input
        elif state["id"] == _STATE.CONFIRM_PROPERTY:
            if input.isspace():
                stack.pop()
                state = stack.pop()
                key = _normalize_key(state["value"])

                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": key,
                    "indent": state["indent"],
                })
                stack.append({
                    "id": _STATE.PARSE_VALUE,
                    "value_on_next_line": input == "\n",
                    "indent": state["indent"],
                    "value": "",
                    "started": False,
                })
            else:
                stack.pop()
                _peek(stack)["value"] += ":" + input
        elif state["id"] == _STATE.PARSE_SEQUENCE:
            if input == "\n" and not state["value"] == "":
                state["sequence"].append(_parse_scalar(state["value"]))
                state["value"] = ""
                state["started"] = False
            elif input == "\n":
                stack.pop()
                property_state = stack.pop()
                _get_current_object(result, stack)[property_state["key"]] = state["sequence"]
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": property_state["indent"],
                })
            elif input.isspace():
                pass
            elif input == "-":
                state["started"] = True
            elif state["started"]:
                state["value"] += input
            else:
                stack.pop()
                property_state = stack.pop()
                _get_current_object(result, stack)[property_state["key"]] = state["sequence"]
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": property_state["indent"],
                })
        elif state["id"] == _STATE.PARSE_BRACKET_SEQUENCE:
            if input.isspace():
                pass
            elif input == ",":
                state["sequence"].append(_parse_scalar(state["value"]))
                state["value"] = ""
            elif input == "]":
                state["sequence"].append(_parse_scalar(state["value"]))
                stack.pop()
                property_state = stack.pop()
                _get_current_object(result, stack)[property_state["key"]] = state["sequence"]
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": property_state["indent"],
                })
            else:
                state["value"] += input
        elif state["id"] == _STATE.AFTER_OBJECT_CLOSE:
            if input == "\n":
                stack.pop()
                if len(stack) > 0:
                    stack.pop()
                    stack.append({
                        "id": _STATE.PROPERTY,
                        "key": "",
                        "indent": _peek(stack)["indent"] if len(stack) > 0 else 0,
                    })
            elif input.isspace():
                pass
            elif input == "}":
                stack.pop()
                stack.pop()
                stack.append({
                    "id": _STATE.AFTER_OBJECT_CLOSE,
                })
            elif input == ",":
                stack.pop()
                stack.pop()
                stack.append({
                    "id": _STATE.PROPERTY,
                    "key": "",
                    "indent": _peek(stack)["indent"],
                })
        else:
            fail("Unknown state %d" % state["id"])
    return result

def _normalize_key(key):
    return key.strip("'")

def _parse_scalar(value):
    if _is_int(value):
        return int(value)
    elif _is_float(value):
        return float(value)
    elif _is_bool(value):
        return _to_bool(value)
    else:
        return value.strip("'")

def _get_current_object(result, stack):
    object = result
    for i in range(len(stack)):
        if stack[i]["id"] == _STATE.PROPERTY:
            object = object.setdefault(stack[i]["key"], {})
    return object

def _is_float(value):
    return value.replace(".", "", 1).isdigit()

def _is_int(value):
    return value.isdigit()

def _is_bool(value):
    return value == "true" or value == "false"

def _to_bool(value):
    if value == "true":
        return True
    elif value == "false":
        return False
    fail("Cannot convert scalar %s to a starlark boolean" % value)

def _peek(stack):
    return stack[-1]
