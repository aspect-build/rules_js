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

starlark_codegen_utils = struct(
    to_list_attr = _to_list_attr,
    to_dict_attr = _to_dict_attr,
    to_dict_list_attr = _to_dict_list_attr,
)
