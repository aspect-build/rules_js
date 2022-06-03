"An experimental (and incomplete) yaml parser for starlark"
# https://github.com/bazelbuild/starlark/issues/219

_STATE = struct(
    # Consume extraneous space and keep track of indent level
    CONSUME_SPACE = 0,
    # Consume whitespace within a flow, where indentation isn't a factor
    CONSUME_SPACE_FLOW = 1,
    # Parse the next key or value
    PARSE_NEXT = 2,
    # Parse the next key or value inside of a flow
    PARSE_NEXT_FLOW = 3,
    # Pseudo-states that don't perform any logic but indicate the current
    # hierarchical result being formed in the starlark output.
    KEY = 4,
    SEQUENCE = 5,
)

def parse(yaml):
    """Parse yaml into starlark

    Args:
        yaml: string, the yaml content to parse

    Returns:
        An equivalent mapping to native starlark types
    """
    yaml = _normalize_yaml(yaml)

    starlark = {"result": None}
    stack = []
    stack.append(_new_CONSUME_SPACE(indent = ""))

    for input in yaml.elems():
        state = _peek(stack)

        if state["id"] == _STATE.CONSUME_SPACE:
            _handle_CONSUME_SPACE(state, input, stack, starlark)
        elif state["id"] == _STATE.CONSUME_SPACE_FLOW:
            _handle_CONSUME_SPACE_FLOW(state, input, stack, starlark)
        elif state["id"] == _STATE.PARSE_NEXT:
            _handle_PARSE_NEXT(state, input, stack, starlark)
        elif state["id"] == _STATE.PARSE_NEXT_FLOW:
            _handle_PARSE_NEXT_FLOW(state, input, stack, starlark)
        else:
            fail("Unknown state %s" % state["id"])

    return starlark["result"]

def _handle_CONSUME_SPACE(state, input, stack, starlark):
    if input == "\n":
        # Reset the indentation
        state["indent"] = ""
    elif input.isspace():
        # Count the leading indentation
        state["indent"] += input
    elif input == "{":
        stack.pop()

        # We are at the beginning of a new flow map
        stack.append(_new_KEY(
            key = "",
            flow = True,
        ))

        _initialize_result_value(starlark, stack)

        # Consume any space following the {
        stack.append(_new_CONSUME_SPACE_FLOW())

    elif input == "[":
        stack.pop()

        # We are at the beginning of a new flow sequence
        stack.append(_new_SEQUENCE(
            index = 0,
            flow = True,
        ))

        _initialize_result_value(starlark, stack)

        # Consume any space following the [
        stack.append(_new_CONSUME_SPACE_FLOW())
    else:
        # Reached the beginning of a value or key
        stack.pop()
        stack.append(_new_PARSE_NEXT(
            indent = state["indent"],
            buffer = input,
        ))

def _handle_PARSE_NEXT(state, input, stack, starlark):
    if input.isspace():
        if state["buffer"].endswith(":"):
            stack.pop()

            # We just parsed a key
            _pop_higher_indented_states(stack, state["indent"])

            if len(stack) < 1 or len(state["indent"]) > len(_peek(stack)["indent"]):
                # The key is part of a new map
                stack.append(_new_KEY(
                    key = _parse_key(state["buffer"][0:-1]),
                    indent = state["indent"],
                    flow = False,
                ))
            else:
                # The key is a sibling in the map
                _peek(stack)["key"] = _parse_key(state["buffer"][0:-1])

            _initialize_result_value(starlark, stack)

            # Consume any space following the key
            stack.append(_new_CONSUME_SPACE(
                indent = state["indent"] if not input == "\n" else "",
            ))
        elif state["buffer"] == "-":
            stack.pop()

            if len(stack) > 0 and stack[-1]["id"] == _STATE.SEQUENCE:
                # We are at the next item in a non-flow sequence
                stack[-1]["index"] += 1
            else:
                # We are at the beginning of a non-flow sequence
                stack.append(_new_SEQUENCE(
                    indent = state["indent"],
                    index = 0,
                    flow = False,
                ))

                _initialize_result_value(starlark, stack)

            # Consume any space following the sequence marker
            stack.append(_new_CONSUME_SPACE(
                indent = state["indent"] if not input == "\n" else "",
            ))
        elif input == "\n":
            stack.pop()

            # We just parsed a scalar
            _set_result_value(starlark, stack, _parse_scalar(state["buffer"]))

            # Consume any space following the scalar
            stack.append(_new_CONSUME_SPACE(
                indent = "",
            ))
        else:
            # Accumulate the space as part of the next thing to parse
            state["buffer"] += input
    else:
        # Accumulate the current text until we know what to do with it
        state["buffer"] += input

def _handle_CONSUME_SPACE_FLOW(state, input, stack, starlark):
    if input.isspace():
        pass
    elif input == "[":
        # We started a new inner flow sequence
        stack.pop()
        stack.append(_new_SEQUENCE(
            index = 0,
            flow = True,
        ))

        _initialize_result_value(starlark, stack)

        # Consume any space following the [
        stack.append(_new_CONSUME_SPACE_FLOW())
    elif input == "{":
        # We started a new inner flow map
        stack.pop()
        stack.append(_new_KEY(
            key = "",
            flow = True,
        ))

        _initialize_result_value(starlark, stack)

        # Consume any space following the {
        stack.append(_new_CONSUME_SPACE_FLOW())
    elif input == "]" and _in_flow_sequence(stack):
        # We are at the end of a flow sequence
        stack.pop()
        stack.pop()

        # Consume any space before the next thing to parse and escape the flow if needed
        stack.append(_new_CONSUME_SPACE_FLOW() if _in_flow(stack) else _new_CONSUME_SPACE(
            indent = _peek(stack)["indent"] if len(stack) > 0 else "",
        ))
    elif input == "}" and _in_flow_map(stack):
        # We are at the end of a flow map
        stack.pop()
        stack.pop()

        # Consume any space before the next thing to parse and escape the flow if needed
        stack.append(_new_CONSUME_SPACE_FLOW() if _in_flow(stack) else _new_CONSUME_SPACE(
            indent = _peek(stack)["indent"] if len(stack) > 0 else "",
        ))
    elif input == "," and _in_flow_map(stack):
        # If we come across a comma but we are in the consume space state,
        # then it means we just parsed a non-scalar which is already in the
        # result, so just move on (I think...)
        stack.pop()

        # Consume any space before the next sequence value
        stack.append(_new_CONSUME_SPACE_FLOW())
    else:
        # Reached the beginning of a value or key
        stack.pop()
        stack.append(_new_PARSE_NEXT_FLOW(
            buffer = input,
        ))

def _handle_PARSE_NEXT_FLOW(state, input, stack, starlark):
    if input == "[":
        fail("Unhandled case")
    elif input == "," and _in_flow_sequence(stack):
        # We parsed the next value in a flow sequence
        _set_result_value(starlark, stack, _parse_scalar(state["buffer"]))
        stack.pop()

        sequence_flow_state = _peek(stack)
        sequence_flow_state["index"] += 1

        # Consume any space before the next sequence value
        stack.append(_new_CONSUME_SPACE_FLOW())
    elif input == "," and _in_flow_map(stack):
        # We parsed the a value corresponding to the current key
        _set_result_value(starlark, stack, _parse_scalar(state["buffer"]))
        stack.pop()

        # Reset the key
        map_flow_state = _peek(stack)
        map_flow_state["key"] = ""

        # Consume any space before the next sequence value
        stack.append(_new_CONSUME_SPACE_FLOW())
    elif input == "]" and _in_flow_sequence(stack):
        # We are at the end of a flow sequence
        _set_result_value(starlark, stack, _parse_scalar(state["buffer"]))
        stack.pop()
        stack.pop()

        # Consume any space before the next thing to parse and escape the flow if needed
        stack.append(_new_CONSUME_SPACE_FLOW() if _in_flow(stack) else _new_CONSUME_SPACE(
            indent = _peek(stack)["indent"] if len(stack) > 0 else "",
        ))
    elif input == "}" and _in_flow_map(stack):
        # We are at the end of a flow map
        _set_result_value(starlark, stack, _parse_scalar(state["buffer"]))
        stack.pop()
        stack.pop()

        # Consume any space before the next thing to parse and escape the flow if needed
        stack.append(_new_CONSUME_SPACE_FLOW() if _in_flow(stack) else _new_CONSUME_SPACE(
            indent = _peek(stack)["indent"] if len(stack) > 0 else "",
        ))
    elif input.isspace() and state["buffer"].endswith(":") and _in_flow_map(stack):
        # We just parsed a key
        stack.pop()
        _peek(stack)["key"] = _parse_key(state["buffer"][0:-1])

        stack.append(_new_CONSUME_SPACE_FLOW())
    else:
        state["buffer"] += input

def _new_CONSUME_SPACE(indent):
    return {
        "id": _STATE.CONSUME_SPACE,
        "indent": indent,
    }

def _new_CONSUME_SPACE_FLOW():
    return {
        "id": _STATE.CONSUME_SPACE_FLOW,
    }

def _new_PARSE_NEXT(indent, buffer):
    return {
        "id": _STATE.PARSE_NEXT,
        "indent": indent,
        "buffer": buffer,
    }

def _new_PARSE_NEXT_FLOW(buffer):
    return {
        "id": _STATE.PARSE_NEXT_FLOW,
        "buffer": buffer,
    }

def _new_KEY(key, flow, indent = None):
    return {
        "id": _STATE.KEY,
        "key": key,
        "indent": indent if not flow else None,
        "flow": flow,
    }

def _new_SEQUENCE(index, flow, indent = None):
    return {
        "id": _STATE.SEQUENCE,
        "indent": indent if not flow else None,
        "index": index,
        "flow": flow,
    }

def _normalize_yaml(yaml):
    yaml = yaml.replace("\r", "")
    if not yaml.endswith("\n"):
        yaml = yaml + "\n"
    return yaml

def _initialize_result_value(starlark, stack):
    "Initialize empty starlark maps or list values for the current pseudostates in the stack"
    kns_states = _get_key_and_sequence_states(stack)

    if len(kns_states) == 0:
        return
    else:
        if starlark["result"] == None:
            starlark["result"] = _empty_value_for_state(kns_states[0])
        curr_result = starlark["result"]
        for (i, state) in enumerate(kns_states[0:-1]):
            if type(curr_result) == "dict":
                curr_result = curr_result.setdefault(state["key"], _empty_value_for_state(kns_states[i + 1]))
            else:
                if state["index"] >= len(curr_result):
                    curr_result.append(_empty_value_for_state(kns_states[i + 1]))
                curr_result = curr_result[state["index"]]

def _set_result_value(starlark, stack, value):
    "Add a new value to the starlark result corresponding to the last pseudostate in the stack"
    kns_states = _get_key_and_sequence_states(stack)
    if len(kns_states) == 0:
        starlark["result"] = value
    else:
        curr_result = starlark["result"]
        for state in kns_states[0:-1]:
            if type(curr_result) == "dict":
                curr_result = curr_result[state["key"]]
            else:
                curr_result = curr_result[state["index"]]
        if type(curr_result) == "dict":
            curr_result[kns_states[-1]["key"]] = value
        else:
            curr_result.append(value)

def _empty_value_for_state(state):
    if state["id"] == _STATE.KEY:
        return {}
    elif state["id"] == _STATE.SEQUENCE:
        return []
    else:
        fail("State %s has no empty type" % state["id"])

def _peek(stack):
    return stack[-1]

def _parse_scalar(value):
    value = value.strip()
    if _is_int(value):
        return int(value)
    elif _is_float(value):
        return float(value)
    elif _is_bool(value):
        return _to_bool(value)
    elif value.startswith("'"):
        return value.strip("'")
    else:
        return value.strip("\"")

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

def _parse_key(key):
    if key.startswith("'"):
        return key.strip("'")
    elif key.startswith("\""):
        return key.strip("\"")
    return key

def _get_key_and_sequence_states(stack):
    return [state for state in stack if state["id"] in [_STATE.KEY, _STATE.SEQUENCE]]

def _in_flow(stack):
    kns_states = _get_key_and_sequence_states(stack)
    return len(kns_states) > 0 and kns_states[-1]["id"] in [_STATE.SEQUENCE, _STATE.KEY] and kns_states[-1]["flow"]

def _in_flow_sequence(stack):
    kns_states = _get_key_and_sequence_states(stack)
    return len(kns_states) > 0 and kns_states[-1]["id"] == _STATE.SEQUENCE and kns_states[-1]["flow"]

def _in_flow_map(stack):
    kns_states = _get_key_and_sequence_states(stack)
    return len(kns_states) > 0 and kns_states[-1]["id"] == _STATE.KEY and kns_states[-1]["flow"]

def _pop_higher_indented_states(stack, indent):
    remove = []
    for state in stack:
        if state["id"] in [_STATE.KEY, _STATE.SEQUENCE] and len(state["indent"]) > len(indent):
            remove.append(state)
    for state in remove:
        stack.remove(state)
