"""Performance validation tests for platform utilities caching."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:platform_utils.bzl", 
     "create_platform_cache", 
     "get_normalized_platform",
     "get_normalized_platform_cached",
     "is_package_compatible_with_platform",
     "is_package_compatible_with_platform_cached")

def _test_caching_performance_benefit(ctx):
    """Validate that caching provides performance benefits by avoiding redundant work."""
    env = unittest.begin(ctx)
    
    # Create cache
    cache = create_platform_cache()
    
    # Test data - common platform combinations that would be checked repeatedly
    test_platforms = [
        ("Mac OS X", "amd64"),
        ("Linux", "x86_64"), 
        ("Windows 10", "aarch64"),
        ("Mac OS X", "amd64"),  # Duplicate to test cache hit
        ("Linux", "x86_64"),   # Duplicate to test cache hit
    ]
    
    # Test without cache (baseline) - each call does full computation
    for os_name, cpu_name in test_platforms:
        result = get_normalized_platform(os_name, cpu_name)
        # Verify results are correct
        asserts.true(env, len(result) == 2)
        asserts.true(env, type(result[0]) == "string")
        asserts.true(env, type(result[1]) == "string")
    
    # Test with cache - should benefit from caching duplicate calls
    cache_results = []
    for os_name, cpu_name in test_platforms:
        result = get_normalized_platform_cached(os_name, cpu_name, cache)
        cache_results.append(result)
        # Verify results are still correct
        asserts.true(env, len(result) == 2)
        asserts.true(env, type(result[0]) == "string")
        asserts.true(env, type(result[1]) == "string")
    
    # Verify cache has expected number of unique entries
    # We have 3 unique platform combinations, so cache should have 3 entries
    asserts.equals(env, 3, len(cache))
    
    # Verify cache contains expected keys
    expected_keys = ["Mac OS X||amd64", "Linux||x86_64", "Windows 10||aarch64"]
    for key in expected_keys:
        asserts.true(env, key in cache)
    
    # Verify cached results match non-cached results
    non_cached_results = [
        get_normalized_platform("Mac OS X", "amd64"),
        get_normalized_platform("Linux", "x86_64"),
        get_normalized_platform("Windows 10", "aarch64"),
        get_normalized_platform("Mac OS X", "amd64"),
        get_normalized_platform("Linux", "x86_64"),
    ]
    
    asserts.equals(env, non_cached_results, cache_results)
    
    return unittest.end(env)

def _test_constraint_caching_performance(ctx):
    """Test that constraint validation caching provides benefits for repeated checks."""
    env = unittest.begin(ctx)
    
    cache = create_platform_cache()
    
    # Common constraint patterns that would be checked repeatedly in a large dependency tree
    test_constraints = [
        (["darwin", "linux"], ["x64", "arm64"], "darwin", "x64"),
        (["win32"], ["x64"], "win32", "x64"),
        (None, None, "darwin", "x64"),  # No constraints
        (["darwin", "linux"], ["x64", "arm64"], "darwin", "x64"),  # Duplicate
        (None, None, "linux", "arm64"),  # No constraints duplicate
    ]
    
    # Test with caching
    cached_results = []
    for package_os, package_cpu, current_os, current_cpu in test_constraints:
        result = is_package_compatible_with_platform_cached(
            package_os, package_cpu, current_os, current_cpu, cache
        )
        cached_results.append(result)
    
    # Test without caching for comparison
    non_cached_results = []
    for package_os, package_cpu, current_os, current_cpu in test_constraints:
        result = is_package_compatible_with_platform(
            package_os, package_cpu, current_os, current_cpu
        )
        non_cached_results.append(result)
    
    # Results should be identical
    asserts.equals(env, non_cached_results, cached_results)
    
    # Verify cache behavior:
    # - Early exit for no constraints shouldn't cache (2 cases)
    # - Real constraint checks should cache (2 unique patterns)
    # Expected cache size: 2 (the two constraint patterns that actually get cached)
    asserts.equals(env, 2, len(cache))
    
    # Verify expected results
    expected_results = [True, True, True, True, True]  # All should be compatible
    asserts.equals(env, expected_results, cached_results)
    
    return unittest.end(env)

def _test_cache_isolation(ctx):
    """Test that different caches are isolated from each other."""
    env = unittest.begin(ctx)
    
    cache1 = create_platform_cache()
    cache2 = create_platform_cache()
    
    # Add data to cache1
    get_normalized_platform_cached("Mac OS X", "amd64", cache1)
    asserts.equals(env, 1, len(cache1))
    asserts.equals(env, 0, len(cache2))
    
    # Add different data to cache2
    get_normalized_platform_cached("Linux", "x86_64", cache2)
    asserts.equals(env, 1, len(cache1))
    asserts.equals(env, 1, len(cache2))
    
    # Verify caches contain different data
    asserts.true(env, "Mac OS X||amd64" in cache1)
    asserts.false(env, "Mac OS X||amd64" in cache2)
    asserts.false(env, "Linux||x86_64" in cache1)
    asserts.true(env, "Linux||x86_64" in cache2)
    
    return unittest.end(env)

def _test_large_scale_simulation(ctx):
    """Simulate processing a large dependency tree with many platform checks."""
    env = unittest.begin(ctx)
    
    cache = create_platform_cache()
    
    # Simulate processing 100 packages with common platform patterns
    # This represents what might happen in a large monorepo
    package_count = 100
    platform_patterns = [
        (["darwin", "linux"], ["x64", "arm64"]),  # Common cross-platform
        (["linux"], ["x64"]),                     # Linux-only
        (["win32"], ["x64", "ia32"]),            # Windows-only
        (None, None),                             # No constraints
        (["darwin"], ["arm64"]),                  # Apple Silicon specific
    ]
    
    current_platform = ("darwin", "x64")
    
    # Process packages
    results = []
    for i in range(package_count):
        # Cycle through platform patterns (simulating real dependency mix)
        pattern_idx = i % len(platform_patterns) 
        package_os, package_cpu = platform_patterns[pattern_idx]
        
        result = is_package_compatible_with_platform_cached(
            package_os, package_cpu, current_platform[0], current_platform[1], cache
        )
        results.append(result)
    
    # Verify we processed all packages
    asserts.equals(env, package_count, len(results))
    
    # Cache should contain only unique constraint patterns (minus early exits)
    # Patterns with actual constraints: 4 (excluding None, None)
    # Early exit patterns don't get cached, so we expect 4 cache entries
    asserts.equals(env, 4, len(cache))
    
    # Verify expected compatibility results
    # Let's check what we actually expect for each pattern:
    # Pattern 0: (["darwin", "linux"], ["x64", "arm64"]) -> compatible (darwin matches, x64 matches)
    # Pattern 1: (["linux"], ["x64"]) -> incompatible (linux doesn't match darwin)  
    # Pattern 2: (["win32"], ["x64", "ia32"]) -> incompatible (win32 doesn't match darwin)
    # Pattern 3: (None, None) -> compatible (no constraints)
    # Pattern 4: (["darwin"], ["arm64"]) -> incompatible (darwin matches but arm64 doesn't match x64)
    
    # Count actual results by pattern
    compatible_patterns = []
    for i, (package_os, package_cpu) in enumerate(platform_patterns):
        if not package_os and not package_cpu:
            compatible_patterns.append(i)  # No constraints = compatible
        elif package_os and "darwin" in package_os and package_cpu and "x64" in package_cpu:
            compatible_patterns.append(i)  # Both OS and CPU match
        elif package_os and "darwin" in package_os and not package_cpu:
            compatible_patterns.append(i)  # OS matches, no CPU constraint
        elif not package_os and package_cpu and "x64" in package_cpu:
            compatible_patterns.append(i)  # No OS constraint, CPU matches
    
    # Expected compatible patterns: 0 (darwin+x64 matches), 3 (no constraints)
    # So 2 patterns out of 5 are compatible
    packages_per_pattern = package_count // len(platform_patterns)
    expected_total_compatible = len(compatible_patterns) * packages_per_pattern
    actual_compatible = len([r for r in results if r])
    
    # Debug: let's be more explicit about what we expect
    # Pattern 0: ["darwin", "linux"] + ["x64", "arm64"] with current darwin/x64 -> True
    # Pattern 1: ["linux"] + ["x64"] with current darwin/x64 -> False (OS mismatch)
    # Pattern 2: ["win32"] + ["x64", "ia32"] with current darwin/x64 -> False (OS mismatch)  
    # Pattern 3: None + None with current darwin/x64 -> True (no constraints)
    # Pattern 4: ["darwin"] + ["arm64"] with current darwin/x64 -> False (CPU mismatch)
    
    # So patterns 0 and 3 should be compatible = 2 out of 5 patterns
    # With 100 packages, 20 packages per pattern = 40 compatible total
    asserts.equals(env, 40, actual_compatible)
    
    return unittest.end(env)

# Test suite definition  
caching_performance_test = unittest.make(_test_caching_performance_benefit)
constraint_caching_performance_test = unittest.make(_test_constraint_caching_performance)
cache_isolation_test = unittest.make(_test_cache_isolation)
large_scale_simulation_test = unittest.make(_test_large_scale_simulation)

def platform_performance_test_suite():
    """Performance validation test suite for platform utilities."""
    unittest.suite(
        "platform_performance_tests",
        caching_performance_test,
        constraint_caching_performance_test,
        cache_isolation_test,
        large_scale_simulation_test,
    ) 