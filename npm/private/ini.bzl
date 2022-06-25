"""
INI utils

See https://en.wikipedia.org/wiki/INI_file
"""

def parse_ini(init_content):
    """Parse standard INI string into key/value map.

    Duplicate keys override previous values.
    Keys are converted to lowercase.

    Supports:
    * basic key/value
    * # or ; comments

    Does NOT support or ignores:
    * sections
    * escape characters
    * number or boolean types (all values are strings)
    * comment characters (#, ;) within a value

    https://en.wikipedia.org/wiki/INI_file#Format

    Args:
        init_content: the INI content string

    Returns:
        A dict() of key/value pairs of the INI properties
    """

    props = []

    for line in init_content.splitlines():
        line = line.strip()

        # Ignore sections
        if line.startswith("["):
            continue

        # Strip comments
        line = line.split(";", 2)[0]
        line = line.split("#", 2)[0]

        # Empty or was all comments
        if len(line) == 0:
            continue

        [name, _, value] = line.strip().partition("=")

        props.append([name.strip().lower(), value.strip()])

    return dict(props)
