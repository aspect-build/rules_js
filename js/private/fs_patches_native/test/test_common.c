/*
 * test_common.c — Unit tests for fs_patch_common.c core logic
 *
 * Tests: is_sub_path, check_escape, normalize_path, make_absolute
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>
#include "../fs_patch.h"

/* --------------------------------------------------------------------------
 * Minimal test harness
 * -------------------------------------------------------------------------- */

#define TEST(name) static void name(void)
#define RUN_TEST(name) do { printf("  %s...", #name); name(); printf(" OK\n"); } while(0)
#define ASSERT_EQ(a, b) do { \
    long long _a = (long long)(a), _b = (long long)(b); \
    if (_a != _b) { \
        fprintf(stderr, "FAIL: %s:%d: %lld != %lld\n", __FILE__, __LINE__, _a, _b); \
        exit(1); \
    } \
} while(0)
#define ASSERT_STREQ(a, b) do { \
    const char *_a = (a), *_b = (b); \
    if (strcmp(_a, _b) != 0) { \
        fprintf(stderr, "FAIL: %s:%d: \"%s\" != \"%s\"\n", __FILE__, __LINE__, _a, _b); \
        exit(1); \
    } \
} while(0)
#define ASSERT_NULL(a) do { \
    if ((a) != NULL) { \
        fprintf(stderr, "FAIL: %s:%d: expected NULL\n", __FILE__, __LINE__); \
        exit(1); \
    } \
} while(0)
#define ASSERT_NOT_NULL(a) do { \
    if ((a) == NULL) { \
        fprintf(stderr, "FAIL: %s:%d: unexpected NULL\n", __FILE__, __LINE__); \
        exit(1); \
    } \
} while(0)

/* --------------------------------------------------------------------------
 * Helper: reset g_config to a known state
 * -------------------------------------------------------------------------- */

static void reset_config(void) {
    for (int i = 0; i < g_config.num_roots; i++) {
        free(g_config.roots[i]);
        g_config.roots[i] = NULL;
    }
    g_config.num_roots = 0;
    g_config.enabled = 0;
    g_config.debug = 0;
}

static void set_roots(const char **roots, int count) {
    reset_config();
    for (int i = 0; i < count && i < FS_PATCH_MAX_ROOTS; i++) {
        g_config.roots[i] = strdup(roots[i]);
    }
    g_config.num_roots = count;
    g_config.enabled = 1;
}

/* --------------------------------------------------------------------------
 * is_sub_path tests
 * -------------------------------------------------------------------------- */

TEST(test_is_sub_path_exact_match) {
    ASSERT_EQ(is_sub_path("/a/b", "/a/b"), 1);
}

TEST(test_is_sub_path_child) {
    ASSERT_EQ(is_sub_path("/a/b", "/a/b/c/d"), 1);
}

TEST(test_is_sub_path_parent_longer) {
    ASSERT_EQ(is_sub_path("/a/b", "/a"), 0);
}

TEST(test_is_sub_path_false_prefix) {
    /* Critical edge case: "/a/b" must NOT match "/a/bc" */
    ASSERT_EQ(is_sub_path("/a/b", "/a/bc"), 0);
}

TEST(test_is_sub_path_different_subtree) {
    ASSERT_EQ(is_sub_path("/a/b", "/a/c/b"), 0);
}

TEST(test_is_sub_path_root_matches_all) {
    ASSERT_EQ(is_sub_path("/", "/anything"), 1);
}

TEST(test_is_sub_path_completely_different) {
    ASSERT_EQ(is_sub_path("/a/b", "/x/y"), 0);
}

/* --------------------------------------------------------------------------
 * check_escape tests
 * -------------------------------------------------------------------------- */

TEST(test_check_escape_in_root_to_in_root) {
    const char *roots[] = {"/sandbox", "/runfiles"};
    set_roots(roots, 2);
    /* Link in /sandbox, target also in /sandbox — no escape */
    ASSERT_EQ(check_escape("/sandbox/link", "/sandbox/target"), -1);
}

TEST(test_check_escape_in_root_to_outside) {
    const char *roots[] = {"/sandbox", "/runfiles"};
    set_roots(roots, 2);
    /* Link in /sandbox, target outside — escape detected */
    int result = check_escape("/sandbox/link", "/outside/target");
    ASSERT_EQ(result >= 0, 1); /* Should return root index */
}

TEST(test_check_escape_outside_to_anywhere) {
    const char *roots[] = {"/sandbox", "/runfiles"};
    set_roots(roots, 2);
    /* Link outside any root — not our concern, returns -1 */
    ASSERT_EQ(check_escape("/other/link", "/outside/target"), -1);
}

TEST(test_check_escape_root_a_to_root_b) {
    const char *roots[] = {"/sandbox", "/runfiles"};
    set_roots(roots, 2);
    /* Link in /sandbox, target in /runfiles — escaped from sandbox */
    int result = check_escape("/sandbox/link", "/runfiles/target");
    ASSERT_EQ(result >= 0, 1); /* Should return index of /sandbox root */
}

/* --------------------------------------------------------------------------
 * normalize_path tests
 * -------------------------------------------------------------------------- */

TEST(test_normalize_path_dotdot) {
    char buf[PATH_MAX];
    char *result = normalize_path("/a/b/../c", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/a/c");
}

TEST(test_normalize_path_dot) {
    char buf[PATH_MAX];
    char *result = normalize_path("/a/./b/./c", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/a/b/c");
}

TEST(test_normalize_path_double_slash) {
    char buf[PATH_MAX];
    char *result = normalize_path("/a//b///c", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/a/b/c");
}

TEST(test_normalize_path_root) {
    char buf[PATH_MAX];
    char *result = normalize_path("/", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/");
}

TEST(test_normalize_path_multiple_dotdot) {
    char buf[PATH_MAX];
    char *result = normalize_path("/a/b/../../c", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/c");
}

/* --------------------------------------------------------------------------
 * make_absolute tests
 * -------------------------------------------------------------------------- */

TEST(test_make_absolute_already_absolute) {
    char buf[PATH_MAX];
    char *result = make_absolute("/already/absolute", buf);
    ASSERT_NOT_NULL(result);
    ASSERT_STREQ(result, "/already/absolute");
}

TEST(test_make_absolute_relative) {
    char buf[PATH_MAX];
    char cwd[PATH_MAX];
    ASSERT_NOT_NULL(getcwd(cwd, sizeof(cwd)));

    char *result = make_absolute("relative/path", buf);
    ASSERT_NOT_NULL(result);

    /* Should start with cwd */
    char expected[PATH_MAX];
    snprintf(expected, sizeof(expected), "%s/relative/path", cwd);
    ASSERT_STREQ(result, expected);
}

/* --------------------------------------------------------------------------
 * main
 * -------------------------------------------------------------------------- */

int main(void) {
    /* Initialize orig_* function pointers to real libc functions.
     * We do this manually instead of calling fs_patch_init() to avoid
     * needing environment variables set up. */
    orig_realpath = realpath;
    orig_lstat    = lstat;
    orig_readlink = readlink;

    printf("test_common:\n");

    printf(" is_sub_path:\n");
    RUN_TEST(test_is_sub_path_exact_match);
    RUN_TEST(test_is_sub_path_child);
    RUN_TEST(test_is_sub_path_parent_longer);
    RUN_TEST(test_is_sub_path_false_prefix);
    RUN_TEST(test_is_sub_path_different_subtree);
    RUN_TEST(test_is_sub_path_root_matches_all);
    RUN_TEST(test_is_sub_path_completely_different);

    printf(" check_escape:\n");
    RUN_TEST(test_check_escape_in_root_to_in_root);
    RUN_TEST(test_check_escape_in_root_to_outside);
    RUN_TEST(test_check_escape_outside_to_anywhere);
    RUN_TEST(test_check_escape_root_a_to_root_b);

    printf(" normalize_path:\n");
    RUN_TEST(test_normalize_path_dotdot);
    RUN_TEST(test_normalize_path_dot);
    RUN_TEST(test_normalize_path_double_slash);
    RUN_TEST(test_normalize_path_root);
    RUN_TEST(test_normalize_path_multiple_dotdot);

    printf(" make_absolute:\n");
    RUN_TEST(test_make_absolute_already_absolute);
    RUN_TEST(test_make_absolute_relative);

    printf("All tests passed.\n");
    return 0;
}
