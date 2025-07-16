"Utilities for generating starlark source code"

def _to_list_attr(list, indent_count = 0, indent_size = 4, quote_value = True):
    if not list:
        return "[]"
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

def _to_dict_list_attr(dict, indent_count = 0, indent_size = 4, quote_key = True):
    if not len(dict):
        return "{}"
    tab = " " * indent_size
    indent = tab * indent_count
    result = "{"
    for k, v in dict.items():
        key = "\"{}\"".format(k) if quote_key else k
        result += "\n%s%s%s: %s," % (indent, tab, key, v)
    result += "\n%s}" % indent
    return result

def _to_conditional_dict_attr(
    neutral_deps, 
    platform_specific_deps, 
    indent_count = 0, 
    indent_size = 4, 
    quote_key = True, 
    quote_value = True
):
    """Generate a conditional dictionary using select() statements.
    
    Args:
        neutral_deps: dict of platform-neutral dependencies
        platform_specific_deps: dict mapping platform conditions to dependency dicts
        indent_count: Base indentation level
        indent_size: Spaces per indent level  
        quote_key: Whether to quote dictionary keys
        quote_value: Whether to quote dictionary values
        
    Returns:
        String representation of conditional dict with select() or plain dict
        
    Example output:
        {
            "neutral-dep": "alias1",  
        } | select({
            "@aspect_rules_js//platforms:os_linux_cpu_x64": {
                "platform-dep": "alias2",
            },
            "//conditions:default": {}
        })
    """
    if not neutral_deps and not platform_specific_deps:
        return "{}"
    
    tab = " " * indent_size
    indent = tab * indent_count
    
    parts = []
    
    # Add neutral dependencies first (if any)
    if neutral_deps:
        # Keep {link_root_name} as placeholder for template substitution
        neutral_dict = _to_dict_attr(neutral_deps, indent_count, indent_size, quote_key, quote_value)
        parts.append(neutral_dict)
    
    # Add select() for platform-specific dependencies (if any)
    if platform_specific_deps:
        select_parts = []
        for condition, deps_dict in sorted(platform_specific_deps.items()):
            # Keep {link_root_name} as placeholder for template substitution
            condition_dict = _to_dict_attr(deps_dict, indent_count + 2, indent_size, quote_key, quote_value)
            select_parts.append('%s"%s": %s' % (tab * (indent_count + 1), condition, condition_dict))
        
        # Add default case for incompatible platforms  
        select_parts.append('%s"//conditions:default": {}' % (tab * (indent_count + 1)))
        
        select_block = "select({\n%s\n%s})" % (",\n".join(select_parts), indent)
        parts.append(select_block)
    
    # Combine with | operator if needed
    if len(parts) == 1:
        return parts[0]
    else:
        return " | ".join(parts)

starlark_codegen_utils = struct(
    to_list_attr = _to_list_attr,
    to_dict_attr = _to_dict_attr,
    to_dict_list_attr = _to_dict_list_attr,
    to_conditional_dict_attr = _to_conditional_dict_attr,
)
