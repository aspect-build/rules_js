"Utilities for generating starlark source code"

def _to_list_attr(list, indent_count = 0, indent_size = 4, quote_value = True):
    if not list:
        return "[]"
    if len(list) == 1:
        val = "\"{}\"".format(list[0]) if quote_value else list[0]
        return "[%s]" % val
    tab = " " * indent_size
    indent = tab * indent_count
    result = "["
    for v in list:
        val = "\"{}\"".format(v) if quote_value else v
        result += "\n%s%s%s," % (indent, tab, val)
    result += "\n%s]" % indent
    return result

def _to_dict_attr(dict, indent_count = 0, indent_size = 4, quote_key = True, quote_value = True):
    if not len(dict):
        return "{}"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "{"
    for k, v in dict.items():
        key = "\"{}\"".format(k) if quote_key else k
        val = "\"{}\"".format(v) if quote_value else v
        result += "\n%s%s%s: %s," % (indent, tab, key, val)
    result += "\n%s}" % indent
    return result

def _to_dict_list_attr(dict, indent_count = 0, indent_size = 4, quote_key = True, quote_list_value = True):
    if not len(dict):
        return "{}"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "{"
    for k, v in dict.items():
        key = "\"{}\"".format(k) if quote_key else k
        val = _to_list_attr(v, indent_count + 1, indent_size, quote_value = quote_list_value)
        result += "\n%s%s%s: %s," % (indent, tab, key, val)
    result += "\n%s}" % indent
    return result

def _to_conditional_dict_attr(
        basic,
        groups,
        indent_count = 0,
        indent_size = 4,
        quote_key = True,
        quote_value = True):
    """Generate a conditional dictionary using select() statements.

    Args:
        basic: the always-present dictionary entries
        groups: list of select() constraints to be applied to items in the dict
        indent_count: Base indentation level
        indent_size: Spaces per indent level
        quote_key: Whether to quote dictionary keys
        quote_value: Whether to quote dictionary values

    Returns:
        String representation of conditional dict with select() or plain dict

    Example output:
        {
            "key_a": "value_a",
        } | select({
            ":constraint_of_key_b": {
                "key_b": "value_b",
            },
            "//conditions:default": {}
        })
    """
    tab = " " * indent_size
    indent = tab * indent_count

    parts = []

    if basic:
        parts.append(
            _to_dict_attr(basic, indent_count, indent_size, quote_key, quote_value),
        )

    # Add select() for constrainted entries
    for group in groups:
        select_parts = []
        for condition, cond_dict in group.items():
            condition_dict = _to_dict_attr(cond_dict, indent_count + 1, indent_size, quote_key, quote_value)
            select_parts.append('%s"%s": %s' % (tab * (indent_count + 1), condition, condition_dict))

        # Add default case with no values for incompatible platforms
        select_parts.append('%s"//conditions:default": {},' % (tab * (indent_count + 1)))

        select_block = "select({\n%s\n%s})" % (",\n".join(select_parts), indent)
        parts.append(select_block)

    if not parts:
        # empty
        return "{}"
    elif len(parts) == 1:
        # Combine with | operator if needed
        return parts[0]
    else:
        return " | ".join(parts)

starlark_codegen_utils = struct(
    to_list_attr = _to_list_attr,
    to_dict_attr = _to_dict_attr,
    to_dict_list_attr = _to_dict_list_attr,
    to_conditional_dict_attr = _to_conditional_dict_attr,
)
