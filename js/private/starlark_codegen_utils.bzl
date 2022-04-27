"Utilities for generating starlark source code"

def _to_list_attr(list, indent_count = 0, indent_size = 4):
    if not list:
        return "[]"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "["
    for v in list:
        result += "\n%s%s\"%s\"," % (indent, tab, v)
    result += "\n%s]" % indent
    return result

def _to_dict_attr(dict, indent_count = 0, indent_size = 4):
    if not len(dict):
        return "{}"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "{"
    for k, v in dict.items():
        result += "\n%s%s\"%s\": \"%s\"," % (indent, tab, k, v)
    result += "\n%s}" % indent
    return result

def _to_dict_list_attr(dict, indent_count = 0, indent_size = 4):
    if not len(dict):
        return "{}"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "{"
    for k, v in dict.items():
        result += "\n%s%s\"%s\": %s," % (indent, tab, k, v)
    result += "\n%s}" % indent
    return result

starlark_codegen_utils = struct(
    to_list_attr = _to_list_attr,
    to_dict_attr = _to_dict_attr,
    to_dict_list_attr = _to_dict_list_attr,
)
