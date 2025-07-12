"""Tests for platform utility functions and caching."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:platform_utils.bzl", 
     "create_platform_cache", 
     "get_normalized_platform", 
     "get_normalized_platform_cached",
     "is_package_compatible_with_platform",
     "is_package_compatible_with_platform_cached")

def _test_get_normalized_platform(ctx):
    """Test basic platform normalization."""
    env = unittest.begin(ctx)
    
    # Test macOS normalization
    os, cpu = get_normalized_platform("Mac OS X", "amd64")
    asserts.equals(env, ("darwin", "x64"), (os, cpu))
    
    # Test Linux normalization (should stay the same)
    os, cpu = get_normalized_platform("Linux", "aarch64") 
    asserts.equals(env, ("linux", "arm64"), (os, cpu))
    
    # Test Windows normalization
    os, cpu = get_normalized_platform("Windows 10", "x86_64")
    asserts.equals(env, ("win32", "x64"), (os, cpu))
    
    return unittest.end(env)

def _test_platform_caching(ctx):
    """Test platform detection caching functionality."""
    env = unittest.begin(ctx)
    
    # Create cache
    cache = create_platform_cache()
    asserts.equals(env, {}, cache)  # Should start empty
    
    # First call should compute and cache
    os1, cpu1 = get_normalized_platform_cached("Mac OS X", "amd64", cache)
    asserts.equals(env, ("darwin", "x64"), (os1, cpu1))
    
    # Cache should now contain the result
    expected_key = "Mac OS X||amd64"
    asserts.true(env, expected_key in cache)
    asserts.equals(env, ("darwin", "x64"), cache[expected_key])
    
    # Second call should use cache (we can't directly test this, but at least verify result)
    os2, cpu2 = get_normalized_platform_cached("Mac OS X", "amd64", cache)
    asserts.equals(env, ("darwin", "x64"), (os2, cpu2))
    
    # Different input should create new cache entry
    os3, cpu3 = get_normalized_platform_cached("Linux", "aarch64", cache)
    asserts.equals(env, ("linux", "arm64"), (os3, cpu3))
    
    # Cache should now have 2 entries
    asserts.equals(env, 2, len(cache))
    
    return unittest.end(env)

def _test_compatibility_basic(ctx):
    """Test basic package compatibility checking."""
    env = unittest.begin(ctx)
    
    # No constraints - should be compatible
    asserts.true(env, is_package_compatible_with_platform(None, None, "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform([], [], "linux", "arm64"))
    
    # Matching single constraints 
    asserts.true(env, is_package_compatible_with_platform("darwin", None, "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform(None, "x64", "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform("darwin", "x64", "darwin", "x64"))
    
    # Non-matching single constraints
    asserts.false(env, is_package_compatible_with_platform("linux", None, "darwin", "x64"))
    asserts.false(env, is_package_compatible_with_platform(None, "arm64", "darwin", "x64"))
    asserts.false(env, is_package_compatible_with_platform("linux", "arm64", "darwin", "x64"))
    
    return unittest.end(env)

def _test_compatibility_lists(ctx):
    """Test package compatibility with list constraints."""
    env = unittest.begin(ctx)
    
    # List constraints - matching
    asserts.true(env, is_package_compatible_with_platform(["darwin", "linux"], None, "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform(None, ["x64", "arm64"], "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform(["darwin", "linux"], ["x64", "arm64"], "darwin", "x64"))
    
    # List constraints - non-matching
    asserts.false(env, is_package_compatible_with_platform(["linux", "win32"], None, "darwin", "x64"))
    asserts.false(env, is_package_compatible_with_platform(None, ["arm64", "ia32"], "darwin", "x64"))
    asserts.false(env, is_package_compatible_with_platform(["linux"], ["arm64"], "darwin", "x64"))
    
    return unittest.end(env)

def _test_compatibility_caching(ctx):
    """Test package compatibility caching."""
    env = unittest.begin(ctx)
    
    # Create cache
    cache = create_platform_cache()
    
    # Early exit optimization test - no constraints should return True immediately
    result1 = is_package_compatible_with_platform_cached(None, None, "darwin", "x64", cache)
    asserts.true(env, result1)
    # Cache should be empty since early exit doesn't cache
    asserts.equals(env, 0, len(cache))
    
    # Test with constraints - should cache result
    result2 = is_package_compatible_with_platform_cached("darwin", "x64", "darwin", "x64", cache)
    asserts.true(env, result2)
    asserts.equals(env, 1, len(cache))
    
    # Same call should use cache
    result3 = is_package_compatible_with_platform_cached("darwin", "x64", "darwin", "x64", cache)
    asserts.true(env, result3)
    asserts.equals(env, 1, len(cache))  # Should still be 1 entry
    
    # Different constraints should create new cache entry
    result4 = is_package_compatible_with_platform_cached("linux", "arm64", "darwin", "x64", cache)
    asserts.false(env, result4)
    asserts.equals(env, 2, len(cache))
    
    return unittest.end(env)

def _test_caching_without_cache(ctx):
    """Test that cached functions work without cache parameter."""
    env = unittest.begin(ctx)
    
    # Should fall back to non-cached versions
    os, cpu = get_normalized_platform_cached("Mac OS X", "amd64", None)
    asserts.equals(env, ("darwin", "x64"), (os, cpu))
    
    compatible = is_package_compatible_with_platform_cached("darwin", "x64", "darwin", "x64", None)
    asserts.true(env, compatible)
    
    return unittest.end(env)

def _test_complex_constraints(ctx):
    """Test complex constraint combinations."""
    env = unittest.begin(ctx)
    
    # Mixed string and list constraints
    asserts.true(env, is_package_compatible_with_platform("darwin", ["x64", "arm64"], "darwin", "x64"))
    asserts.true(env, is_package_compatible_with_platform(["darwin", "linux"], "x64", "darwin", "x64"))
    
    # Multiple valid options
    asserts.true(env, is_package_compatible_with_platform(
        ["darwin", "linux", "win32"], 
        ["x64", "arm64", "ia32"], 
        "linux", "arm64"
    ))
    
    # One matching, one not
    asserts.false(env, is_package_compatible_with_platform(
        ["darwin", "linux"],  # OS matches
        ["arm64", "ia32"],    # CPU doesn't match
        "darwin", "x64"
    ))
    
    return unittest.end(env)

def _test_performance_optimizations(ctx):
    """Test that performance optimizations work correctly."""
    env = unittest.begin(ctx)
    
    cache = create_platform_cache()
    
    # Test early exit for empty constraints
    result = is_package_compatible_with_platform_cached(None, None, "darwin", "x64", cache)
    asserts.true(env, result)
    asserts.equals(env, 0, len(cache))  # Should not cache due to early exit
    
    result = is_package_compatible_with_platform_cached([], [], "darwin", "x64", cache)
    asserts.true(env, result)
    asserts.equals(env, 0, len(cache))  # Should not cache due to early exit
    
    # Test that complex constraints still cache
    result = is_package_compatible_with_platform_cached(
        ["darwin", "linux"], ["x64", "arm64"], "darwin", "x64", cache
    )
    asserts.true(env, result)
    asserts.equals(env, 1, len(cache))  # Should cache complex constraints
    
    return unittest.end(env)

# Test suite definition
get_normalized_platform_test = unittest.make(_test_get_normalized_platform)
platform_caching_test = unittest.make(_test_platform_caching)
compatibility_basic_test = unittest.make(_test_compatibility_basic)
compatibility_lists_test = unittest.make(_test_compatibility_lists)
compatibility_caching_test = unittest.make(_test_compatibility_caching)
caching_without_cache_test = unittest.make(_test_caching_without_cache)
complex_constraints_test = unittest.make(_test_complex_constraints)
performance_optimizations_test = unittest.make(_test_performance_optimizations)

def platform_utils_test_suite():
    """Test suite for platform utility functions."""
    unittest.suite(
        "platform_utils_tests",
        get_normalized_platform_test,
        platform_caching_test,
        compatibility_basic_test,
        compatibility_lists_test,
        compatibility_caching_test,
        caching_without_cache_test,
        complex_constraints_test,
        performance_optimizations_test,
    ) 