"""Platform detection and normalization utilities for rules_js"""

def get_normalized_platform(os_name, cpu_name):
    """Normalize platform names to match Node.js conventions.

    Args:
        os_name: Raw OS name from Bazel (e.g., "Mac OS X", "Linux")
        cpu_name: Raw CPU architecture name from Bazel (e.g., "amd64", "aarch64")

    Returns:
        Tuple of (normalized_os, normalized_cpu) using Node.js naming conventions

    Raises:
        fail: If input parameters are invalid or platform cannot be normalized
    """

    # Validate input parameters
    if not os_name or type(os_name) != "string":
        fail("Invalid os_name: must be a non-empty string, got {} of type {}".format(os_name, type(os_name)))
    if not cpu_name or type(cpu_name) != "string":
        fail("Invalid cpu_name: must be a non-empty string, got {} of type {}".format(cpu_name, type(cpu_name)))

    current_os = os_name.lower().strip()
    current_cpu = cpu_name.lower().strip()

    # Validate non-empty after normalization
    if not current_os:
        fail("Invalid os_name: cannot be empty or whitespace-only")
    if not current_cpu:
        fail("Invalid cpu_name: cannot be empty or whitespace-only")

    # Normalize OS names to match Node.js conventions
    if current_os == "mac os x":
        current_os = "darwin"
    elif current_os.startswith("windows"):
        current_os = "win32"
    elif current_os == "linux":
        current_os = "linux"  # Already correct
    elif current_os in ["freebsd", "openbsd", "netbsd", "sunos", "android", "aix", "haiku", "qnx", "nixos", "emscripten", "wasi", "fuchsia", "chromiumos"]:
        # These are already in correct format
        pass
    else:
        # Unknown OS - provide helpful error message
        fail("Unknown OS '{}': supported values are Mac OS X, Linux, Windows, FreeBSD, OpenBSD, NetBSD, SunOS, Android, AIX, Haiku, QNX, NixOS, Emscripten, WASI, Fuchsia, ChromiumOS".format(os_name))

    # Normalize CPU architecture names to match Node.js conventions
    if current_cpu in ["amd64", "x86_64"]:
        current_cpu = "x64"
    elif current_cpu == "aarch64":
        current_cpu = "arm64"
    elif current_cpu == "ppc64le":
        # Node.js typically uses "ppc64" to refer to little-endian PowerPC 64-bit
        current_cpu = "ppc64le"
    elif current_cpu in ["x64", "arm64", "arm", "ia32", "s390x", "ppc64", "ppc64le", "mips64", "riscv32", "riscv64", "wasm32", "wasm64", "loong64", "mips", "mipsel", "ppc", "ppc32", "i386"]:
        # These are already in correct format or Node.js compatible
        pass
    else:
        # For unknown architectures, leave as-is and let the constraint mapping handle incompatibility
        pass

    return current_os, current_cpu

def _validate_platform_constraint(constraint, constraint_name, valid_values = None):
    """Validate a platform constraint format and values.

    Args:
        constraint: The constraint to validate (string, list, or None)
        constraint_name: Name of the constraint for error messages ("os" or "cpu")
        valid_values: Optional list of valid values to check against

    Returns:
        list: Normalized constraint as a list of strings

    Raises:
        fail: If constraint format is invalid
    """

    # Fast path: empty constraint
    if not constraint:
        return []

    # Fast path: pre-validated string
    if type(constraint) == "string":
        # Quick validation for empty/whitespace
        if not constraint.strip():
            fail("Invalid {} constraint: empty or whitespace-only values not allowed".format(constraint_name))
        return [constraint]

    # List validation path
    if type(constraint) == "list":
        # Fast path: empty list
        if not constraint:
            return []

        # Batch validate list elements
        validated_list = []
        for item in constraint:
            if type(item) != "string":
                fail("Invalid {} constraint: all list elements must be strings, got {} of type {}".format(
                    constraint_name,
                    item,
                    type(item),
                ))
            if not item or not item.strip():
                fail("Invalid {} constraint: empty or whitespace-only values not allowed".format(constraint_name))
            validated_list.append(item)

        # Optional value validation (skip for performance when valid_values=None)
        if valid_values:
            for value in validated_list:
                if value not in valid_values:
                    fail("Invalid {} constraint value '{}': must be one of {}".format(
                        constraint_name,
                        value,
                        valid_values,
                    ))

        return validated_list

    # Type error path
    fail("Invalid {} constraint: must be string, list of strings, or None, got {} of type {}".format(
        constraint_name,
        constraint,
        type(constraint),
    ))

def is_package_compatible_with_platform(package_os, package_cpu, current_os, current_cpu):
    """Check if a package is compatible with the given platform.

    Args:
        package_os: OS constraint from package metadata (string, list, or None)
        package_cpu: CPU constraint from package metadata (string, list, or None)
        current_os: Current OS name (normalized to Node.js conventions)
        current_cpu: Current CPU architecture (normalized to Node.js conventions)

    Returns:
        bool: True if compatible or no constraints, False if incompatible

    Raises:
        fail: If constraint formats are invalid
    """

    # Validate and normalize constraints (without restricting values to allow for future platforms)
    package_os_list = _validate_platform_constraint(package_os, "os", None)
    package_cpu_list = _validate_platform_constraint(package_cpu, "cpu", None)

    # Validate current platform parameters (basic validation without value restriction)
    if current_os and type(current_os) != "string":
        fail("Invalid current_os: must be string or None, got {} of type {}".format(current_os, type(current_os)))
    if current_cpu and type(current_cpu) != "string":
        fail("Invalid current_cpu: must be string or None, got {} of type {}".format(current_cpu, type(current_cpu)))

    # No constraints means compatible with all platforms
    if not package_os_list and not package_cpu_list:
        return True

    # Check OS compatibility
    os_compatible = not package_os_list or current_os in package_os_list

    # Check CPU compatibility
    cpu_compatible = not package_cpu_list or current_cpu in package_cpu_list

    return os_compatible and cpu_compatible

def create_platform_cache():
    """Create a platform detection cache for use within a single execution context.

    Returns:
        dict: Cache that can be passed to cached platform functions
    """
    return {}

def get_normalized_platform_cached(os_name, cpu_name, cache = None):
    """Cached version of get_normalized_platform.

    Args:
        os_name: Raw OS name from Bazel
        cpu_name: Raw CPU architecture name from Bazel
        cache: Optional cache dict to store results

    Returns:
        Tuple of (normalized_os, normalized_cpu) using Node.js naming conventions
    """

    # If no cache provided, fall back to non-cached version
    if cache == None:
        return get_normalized_platform(os_name, cpu_name)

    # Create cache key
    cache_key = "{}||{}".format(os_name, cpu_name)

    # Check cache first
    if cache_key in cache:
        return cache[cache_key]

    # Compute and cache result
    result = get_normalized_platform(os_name, cpu_name)
    cache[cache_key] = result
    return result

def is_package_compatible_with_platform_cached(package_os, package_cpu, current_os, current_cpu, cache = None):
    """Cached version of is_package_compatible_with_platform with optimizations.

    Args:
        package_os: OS constraint from package metadata (string, list, or None)
        package_cpu: CPU constraint from package metadata (string, list, or None)
        current_os: Current OS name (normalized to Node.js conventions)
        current_cpu: Current CPU architecture (normalized to Node.js conventions)
        cache: Optional cache dict for constraint validation results

    Returns:
        bool: True if compatible or no constraints, False if incompatible
    """

    # Early exit optimization: if no constraints, always compatible
    if not package_os and not package_cpu:
        return True

    # If no cache provided, fall back to non-cached version
    if cache == None:
        return is_package_compatible_with_platform(package_os, package_cpu, current_os, current_cpu)

    # Create cache key for constraint validation
    # Use repr() to handle both strings and lists consistently
    cache_key = "compat||{}||{}||{}||{}".format(
        repr(package_os),
        repr(package_cpu),
        current_os,
        current_cpu,
    )

    # Check cache first
    if cache_key in cache:
        return cache[cache_key]

    # Compute and cache result
    result = is_package_compatible_with_platform(package_os, package_cpu, current_os, current_cpu)
    cache[cache_key] = result
    return result

def node_os_to_bazel_constraint(node_os):
    """Convert a Node.js OS name to the corresponding Bazel constraint label.

    Args:
        node_os: Node.js OS name (e.g., "darwin", "linux", "win32")

    Returns:
        str: Bazel constraint label (e.g., "@platforms//os:osx")

    Raises:
        fail: If the OS name is not supported
    """
    if not node_os or type(node_os) != "string":
        fail("Invalid node_os: must be a non-empty string, got {} of type {}".format(node_os, type(node_os)))

    # Map Node.js OS names to official Bazel platform constraints only
    # Everything not in the official @platforms package maps to incompatible
    os_map = {
        "darwin": "@platforms//os:osx",
        "linux": "@platforms//os:linux",
        "win32": "@platforms//os:windows",
        "freebsd": "@platforms//os:freebsd",
        "openbsd": "@platforms//os:openbsd",
        "netbsd": "@platforms//os:netbsd",
        "android": "@platforms//os:android",
        # Additional platforms from official Bazel platforms
        "haiku": "@platforms//os:haiku",
        "qnx": "@platforms//os:qnx",
        "nixos": "@platforms//os:nixos",
        "emscripten": "@platforms//os:emscripten",
        "wasi": "@platforms//os:wasi",
        "fuchsia": "@platforms//os:fuchsia",
        "chromiumos": "@platforms//os:chromiumos",
        "uefi": "@platforms//os:uefi",
        # iOS/tvOS/watchOS/visionOS from Apple ecosystem
        "ios": "@platforms//os:ios",
        "tvos": "@platforms//os:tvos",
        "watchos": "@platforms//os:watchos",
        "visionos": "@platforms//os:visionos",
        # VxWorks embedded OS
        "vxworks": "@platforms//os:vxworks",
        # Special "none" OS for bare metal
        "none": "@platforms//os:none",
    }

    constraint = os_map.get(node_os)
    if not constraint:
        # Unknown OS - map to incompatible as Bazel cannot build for it
        constraint = "@platforms//:incompatible"

    return constraint

def node_cpu_to_bazel_constraint(node_cpu):
    """Convert a Node.js CPU architecture to the corresponding Bazel constraint label.

    Args:
        node_cpu: Node.js CPU architecture (e.g., "x64", "arm64", "arm")

    Returns:
        str: Bazel constraint label (e.g., "@platforms//cpu:x86_64")

    Raises:
        fail: If the CPU architecture is not supported
    """
    if not node_cpu or type(node_cpu) != "string":
        fail("Invalid node_cpu: must be a non-empty string, got {} of type {}".format(node_cpu, type(node_cpu)))

    # Map Node.js CPU names to official Bazel platform constraints only
    # Everything not in the official @platforms package maps to incompatible
    cpu_map = {
        "x64": "@platforms//cpu:x86_64",
        "arm64": "@platforms//cpu:aarch64",
        "arm": "@platforms//cpu:arm",
        "ia32": "@platforms//cpu:x86_32",
        # Additional architectures from official Bazel platforms
        "s390x": "@platforms//cpu:s390x",
        "ppc64": "@platforms//cpu:ppc64le",  # Node.js ppc64 typically means little-endian
        "ppc64le": "@platforms//cpu:ppc64le",  # PowerPC 64-bit little-endian
        "mips64": "@platforms//cpu:mips64",
        "mips64el": "@platforms//cpu:mips64",  # mips64el (little-endian) maps to mips64
        "riscv32": "@platforms//cpu:riscv32",
        "riscv64": "@platforms//cpu:riscv64",
        "wasm32": "@platforms//cpu:wasm32",
        "wasm64": "@platforms//cpu:wasm64",
        # ARM variants from official Bazel platforms
        "aarch32": "@platforms//cpu:aarch32",
        "arm64_32": "@platforms//cpu:arm64_32",
        "arm64e": "@platforms//cpu:arm64e",
        "armv6-m": "@platforms//cpu:armv6-m",
        "armv7": "@platforms//cpu:armv7",
        "armv7-m": "@platforms//cpu:armv7-m",
        "armv7e-m": "@platforms//cpu:armv7e-m",
        "armv7e-mf": "@platforms//cpu:armv7e-mf",
        "armv7k": "@platforms//cpu:armv7k",
        "armv8-m": "@platforms//cpu:armv8-m",
        # PowerPC variants
        "ppc": "@platforms//cpu:ppc",
        "ppc32": "@platforms//cpu:ppc32",
        # i386 variant
        "i386": "@platforms//cpu:i386",
        # Cortex variants
        "cortex-r52": "@platforms//cpu:cortex-r52",
        "cortex-r82": "@platforms//cpu:cortex-r82",
    }

    constraint = cpu_map.get(node_cpu)
    if not constraint:
        # Unknown CPU - map to incompatible as Bazel cannot build for it
        constraint = "@platforms//:incompatible"

    return constraint

def build_platform_select_conditions(package_os, package_cpu):
    """Build select() conditions for a package's platform constraints.

    Creates a list of platform constraint combinations that match the package's
    OS and CPU requirements. Can be used with select() to conditionally include
    packages only on compatible platforms.

    Args:
        package_os: OS constraint from package metadata (string, list, or None)
        package_cpu: CPU constraint from package metadata (string, list, or None)

    Returns:
        list: List of constraint label combinations, each representing a platform
              that satisfies the package constraints. Empty list means no constraints.

    Example:
        For package_os=["linux", "darwin"], package_cpu="x64":
        Returns: [
            "@platforms//os:linux and @platforms//cpu:x86_64",
            "@platforms//os:osx and @platforms//cpu:x86_64"
        ]

    Raises:
        fail: If constraint formats are invalid
    """

    # Validate and normalize constraints
    os_list = _validate_platform_constraint(package_os, "os", None)
    cpu_list = _validate_platform_constraint(package_cpu, "cpu", None)

    # No constraints means compatible with all platforms
    if not os_list and not cpu_list:
        return []

    # Handle case where only one type of constraint is specified
    if not os_list:
        # Only CPU constraints - match any OS with specified CPUs
        conditions = []
        for cpu in cpu_list:
            constraint = node_cpu_to_bazel_constraint(cpu)

            # Skip incompatible platforms
            if constraint != "@platforms//:incompatible":
                conditions.append(constraint)
        return conditions

    if not cpu_list:
        # Only OS constraints - match any CPU with specified OSes
        conditions = []
        for os in os_list:
            constraint = node_os_to_bazel_constraint(os)

            # Skip incompatible platforms
            if constraint != "@platforms//:incompatible":
                conditions.append(constraint)
        return conditions

    # Both OS and CPU constraints - create config_setting combinations
    # Only generate combinations for common platforms to avoid config_setting explosion
    supported_combinations = {
        ("linux", "x64"): "@aspect_rules_js//platforms:os_linux_cpu_x64",
        ("linux", "arm64"): "@aspect_rules_js//platforms:os_linux_cpu_arm64",
        ("linux", "arm"): "@aspect_rules_js//platforms:os_linux_cpu_arm",
        ("linux", "ia32"): "@aspect_rules_js//platforms:os_linux_cpu_ia32",
        ("darwin", "x64"): "@aspect_rules_js//platforms:os_darwin_cpu_x64",
        ("darwin", "arm64"): "@aspect_rules_js//platforms:os_darwin_cpu_arm64",
        ("win32", "x64"): "@aspect_rules_js//platforms:os_win32_cpu_x64",
        ("win32", "ia32"): "@aspect_rules_js//platforms:os_win32_cpu_ia32",
        ("win32", "arm64"): "@aspect_rules_js//platforms:os_win32_cpu_arm64",
        ("freebsd", "x64"): "@aspect_rules_js//platforms:os_freebsd_cpu_x64",
        ("freebsd", "arm64"): "@aspect_rules_js//platforms:os_freebsd_cpu_arm64",
        ("android", "arm"): "@aspect_rules_js//platforms:os_android_cpu_arm",
        ("android", "arm64"): "@aspect_rules_js//platforms:os_android_cpu_arm64",
        ("android", "x64"): "@aspect_rules_js//platforms:os_android_cpu_x64",
    }

    conditions = []
    for os in os_list:
        for cpu in cpu_list:
            combination = (os, cpu)
            if combination in supported_combinations:
                conditions.append(supported_combinations[combination])
            else:
                # Check if either OS or CPU maps to incompatible
                os_constraint = node_os_to_bazel_constraint(os)
                cpu_constraint = node_cpu_to_bazel_constraint(cpu)

                if os_constraint == "@platforms//:incompatible" or cpu_constraint == "@platforms//:incompatible":
                    # Skip incompatible platforms entirely
                    continue

                # For unsupported combinations, fall back to OS-only constraint
                # This provides better compatibility than failing completely
                if os_constraint not in conditions:
                    conditions.append(os_constraint)

    return conditions

def build_select_dict_for_platform_compatibility(package_os, package_cpu, compatible_value, incompatible_value = None):
    """Build a select() dictionary for platform-compatible conditional values.

    Creates a select() dict that returns compatible_value on platforms that match
    the package constraints, and incompatible_value (or empty list) otherwise.

    IMPORTANT: This function only includes conditions for platforms that match
    the package's constraints. This prevents Bazel from resolving repository
    labels for incompatible platforms, enabling lazy repository execution.

    Args:
        package_os: OS constraint from package metadata (string, list, or None)
        package_cpu: CPU constraint from package metadata (string, list, or None)
        compatible_value: Value to return on compatible platforms
        incompatible_value: Value to return on incompatible platforms (defaults to [])

    Returns:
        dict or value: Select dict mapping platform conditions to values, or
                      direct value if no constraints

    Example:
        For package_os="linux", package_cpu="x64", compatible_value="//some:target":
        Returns: {
            "@platforms//os:linux and @platforms//cpu:x86_64": "//some:target",
            "//conditions:default": []
        }

        For package_os=None, package_cpu=None (no constraints):
        Returns: "//some:target" (direct value, no select needed)

    Raises:
        fail: If constraint formats are invalid
    """
    if incompatible_value == None:
        incompatible_value = []

    conditions = build_platform_select_conditions(package_os, package_cpu)

    # No constraints means always compatible - return value directly
    if not conditions:
        return compatible_value

    # Build select dict with conditions mapping to compatible value
    # CRITICAL: Only include conditions that match this package's constraints
    # This ensures incompatible repository labels are never referenced
    select_dict = {}
    for condition in conditions:
        select_dict[condition] = compatible_value

    # Add default case for incompatible platforms
    select_dict["//conditions:default"] = incompatible_value

    return select_dict
