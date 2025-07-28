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
    elif current_os in ["freebsd", "openbsd", "netbsd", "sunos", "android", "aix"]:
        # These are already in correct format
        pass
    else:
        # Unknown OS - provide helpful error message
        fail("Unknown OS '{}': supported values are Mac OS X, Linux, Windows, FreeBSD, OpenBSD, NetBSD, SunOS, Android, AIX".format(os_name))
    
    # Normalize CPU architecture names to match Node.js conventions
    if current_cpu in ["amd64", "x86_64"]:
        current_cpu = "x64"
    elif current_cpu == "aarch64":
        current_cpu = "arm64"
    elif current_cpu in ["x64", "arm64", "arm", "ia32", "s390x", "ppc64", "mips64el", "riscv64", "loong64", "wasm32"]:
        # These are already in correct format
        pass
    else:
        # Unknown CPU architecture - provide helpful error message
        fail("Unknown CPU architecture '{}': supported values are amd64, x86_64, aarch64, arm64, arm, ia32, s390x, ppc64, mips64el, riscv64, loong64, wasm32".format(cpu_name))
    
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
                    constraint_name, item, type(item)
                ))
            if not item or not item.strip():
                fail("Invalid {} constraint: empty or whitespace-only values not allowed".format(constraint_name))
            validated_list.append(item)
        
        # Optional value validation (skip for performance when valid_values=None)
        if valid_values:
            for value in validated_list:
                if value not in valid_values:
                    fail("Invalid {} constraint value '{}': must be one of {}".format(
                        constraint_name, value, valid_values
                    ))
        
        return validated_list
    
    # Type error path
    fail("Invalid {} constraint: must be string, list of strings, or None, got {} of type {}".format(
        constraint_name, constraint, type(constraint)
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
        repr(package_os), repr(package_cpu), current_os, current_cpu
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
    
    # Map Node.js OS names to Bazel constraint labels
    os_map = {
        "darwin": "@platforms//os:osx",
        "linux": "@platforms//os:linux", 
        "win32": "@platforms//os:windows",
        "freebsd": "@platforms//os:freebsd",
        "openbsd": "@platforms//os:openbsd",
        "android": "@platforms//os:android",
        # AIX, NetBSD and SunOS don't have standard Bazel constraints, use custom ones
        "aix": "@aspect_rules_js//platforms/os:aix",
        "netbsd": "@aspect_rules_js//platforms/os:netbsd",
        "sunos": "@aspect_rules_js//platforms/os:sunos",
    }
    
    constraint = os_map.get(node_os)
    if not constraint:
        fail("Unsupported Node.js OS '{}': supported values are {}".format(
            node_os, os_map.keys()
        ))
    
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
    
    # Map Node.js CPU names to Bazel constraint labels
    cpu_map = {
        "x64": "@platforms//cpu:x86_64",
        "arm64": "@platforms//cpu:aarch64", 
        "arm": "@platforms//cpu:arm",
        "ia32": "@platforms//cpu:x86_32",
        # Less common architectures use custom constraints
        "s390x": "@aspect_rules_js//platforms/cpu:s390x",
        "ppc64": "@aspect_rules_js//platforms/cpu:ppc64",
        "mips64el": "@aspect_rules_js//platforms/cpu:mips64el",
        "riscv64": "@aspect_rules_js//platforms/cpu:riscv64",
        "loong64": "@aspect_rules_js//platforms/cpu:loong64",
        "wasm32": "@aspect_rules_js//platforms/cpu:wasm32",
    }
    
    constraint = cpu_map.get(node_cpu)
    if not constraint:
        fail("Unsupported Node.js CPU '{}': supported values are {}".format(
            node_cpu, cpu_map.keys()
        ))
    
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
        return [node_cpu_to_bazel_constraint(cpu) for cpu in cpu_list]
    
    if not cpu_list:
        # Only OS constraints - match any CPU with specified OSes  
        return [node_os_to_bazel_constraint(os) for os in os_list]
    
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
                # For unsupported combinations, fall back to OS-only constraint
                # This provides better compatibility than failing completely
                os_constraint = node_os_to_bazel_constraint(os)
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