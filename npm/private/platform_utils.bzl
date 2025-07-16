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
    elif current_os in ["freebsd", "openbsd", "netbsd", "sunos", "android"]:
        # These are already in correct format
        pass
    else:
        # Unknown OS - provide helpful error message
        fail("Unknown OS '{}': supported values are Mac OS X, Linux, Windows, FreeBSD, OpenBSD, NetBSD, SunOS, Android".format(os_name))
    
    # Normalize CPU architecture names to match Node.js conventions
    if current_cpu in ["amd64", "x86_64"]:
        current_cpu = "x64"
    elif current_cpu == "aarch64":
        current_cpu = "arm64"
    elif current_cpu in ["x64", "arm64", "arm", "ia32", "s390x", "ppc64", "mips64el", "riscv64", "loong64"]:
        # These are already in correct format
        pass
    else:
        # Unknown CPU architecture - provide helpful error message
        fail("Unknown CPU architecture '{}': supported values are amd64, x86_64, aarch64, arm64, arm, ia32, s390x, ppc64, mips64el, riscv64, loong64".format(cpu_name))
    
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