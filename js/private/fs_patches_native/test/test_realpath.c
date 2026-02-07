/*
 * test_realpath.c — Unit tests for guarded_realpath
 *
 * Creates real symlinks in temp directories to test that guarded_realpath
 * correctly follows in-root symlinks and stops at escaping symlinks.
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
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
        fprintf(stderr, "FAIL: %s:%d: expected NULL, got \"%s\"\n", \
                __FILE__, __LINE__, (const char *)(a)); \
        exit(1); \
    } \
} while(0)
#define ASSERT_NOT_NULL(a) do { \
    if ((a) == NULL) { \
        fprintf(stderr, "FAIL: %s:%d: unexpected NULL (errno=%d: %s)\n", \
                __FILE__, __LINE__, errno, strerror(errno)); \
        exit(1); \
    } \
} while(0)

/* --------------------------------------------------------------------------
 * Test fixtures
 * -------------------------------------------------------------------------- */

static char sandbox_dir[PATH_MAX];   /* resolved path to sandbox temp dir */
static char external_dir[PATH_MAX];  /* resolved path to external temp dir */

static void create_file(const char *path) {
    FILE *f = fopen(path, "w");
    if (!f) {
        fprintf(stderr, "Failed to create file: %s (%s)\n", path, strerror(errno));
        exit(1);
    }
    fprintf(f, "test content\n");
    fclose(f);
}

static void setup(void) {
    char sandbox_tmpl[PATH_MAX];
    char external_tmpl[PATH_MAX];

    snprintf(sandbox_tmpl, sizeof(sandbox_tmpl), "/tmp/test_sandbox_XXXXXX");
    snprintf(external_tmpl, sizeof(external_tmpl), "/tmp/test_external_XXXXXX");

    char *sd = mkdtemp(sandbox_tmpl);
    char *ed = mkdtemp(external_tmpl);
    if (!sd || !ed) {
        fprintf(stderr, "mkdtemp failed: %s\n", strerror(errno));
        exit(1);
    }

    /* Resolve to canonical paths */
    if (!realpath(sd, sandbox_dir) || !realpath(ed, external_dir)) {
        fprintf(stderr, "realpath failed: %s\n", strerror(errno));
        exit(1);
    }

    /* Create sandbox structure:
     *   sandbox_dir/a.txt
     *   sandbox_dir/subdir/
     *   sandbox_dir/link_in -> a.txt         (in-root symlink)
     *   sandbox_dir/link_out -> external/b.txt (escaping symlink)
     */
    char path[PATH_MAX];

    snprintf(path, sizeof(path), "%s/a.txt", sandbox_dir);
    create_file(path);

    snprintf(path, sizeof(path), "%s/subdir", sandbox_dir);
    if (mkdir(path, 0755) != 0) {
        fprintf(stderr, "mkdir failed: %s (%s)\n", path, strerror(errno));
        exit(1);
    }

    /* In-root symlink: link_in -> a.txt (relative) */
    char linkpath[PATH_MAX];
    snprintf(linkpath, sizeof(linkpath), "%s/link_in", sandbox_dir);
    if (symlink("a.txt", linkpath) != 0) {
        fprintf(stderr, "symlink failed: %s (%s)\n", linkpath, strerror(errno));
        exit(1);
    }

    /* External directory with a file */
    snprintf(path, sizeof(path), "%s/b.txt", external_dir);
    create_file(path);

    /* Escaping symlink: link_out -> external_dir/b.txt (absolute) */
    char target[PATH_MAX];
    snprintf(target, sizeof(target), "%s/b.txt", external_dir);
    snprintf(linkpath, sizeof(linkpath), "%s/link_out", sandbox_dir);
    if (symlink(target, linkpath) != 0) {
        fprintf(stderr, "symlink failed: %s -> %s (%s)\n", linkpath, target, strerror(errno));
        exit(1);
    }

    /* Configure g_config with sandbox_dir as root */
    g_config.roots[0] = strdup(sandbox_dir);
    g_config.num_roots = 1;
    g_config.enabled = 1;
    g_config.debug = 0;
}

static void teardown(void) {
    char cmd[PATH_MAX * 2 + 16];
    snprintf(cmd, sizeof(cmd), "rm -rf %s %s", sandbox_dir, external_dir);
    (void)system(cmd);

    for (int i = 0; i < g_config.num_roots; i++) {
        free(g_config.roots[i]);
        g_config.roots[i] = NULL;
    }
    g_config.num_roots = 0;
    g_config.enabled = 0;
}

/* --------------------------------------------------------------------------
 * Tests
 * -------------------------------------------------------------------------- */

TEST(test_guarded_realpath_regular_file) {
    /* Regular file in sandbox should resolve normally */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/a.txt", sandbox_dir);

    char resolved[PATH_MAX];
    char *result = guarded_realpath(path, resolved);
    ASSERT_NOT_NULL(result);

    /* Should resolve to the real path of a.txt */
    char expected[PATH_MAX];
    snprintf(expected, sizeof(expected), "%s/a.txt", sandbox_dir);
    ASSERT_STREQ(result, expected);
}

TEST(test_guarded_realpath_in_root_symlink) {
    /* In-root symlink: link_in -> a.txt — should follow and resolve */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/link_in", sandbox_dir);

    char resolved[PATH_MAX];
    char *result = guarded_realpath(path, resolved);
    ASSERT_NOT_NULL(result);

    /* Should resolve to the real path of a.txt (followed the symlink) */
    char expected[PATH_MAX];
    snprintf(expected, sizeof(expected), "%s/a.txt", sandbox_dir);
    ASSERT_STREQ(result, expected);
}

TEST(test_guarded_realpath_escaping_symlink) {
    /* Escaping symlink: link_out -> external_dir/b.txt
     * Should NOT follow to the external target.
     * Instead should return the link path itself. */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/link_out", sandbox_dir);

    char resolved[PATH_MAX];
    char *result = guarded_realpath(path, resolved);
    ASSERT_NOT_NULL(result);

    /* The result should be the link path, not the external target */
    char not_expected[PATH_MAX];
    snprintf(not_expected, sizeof(not_expected), "%s/b.txt", external_dir);

    /* Result should NOT be the external path */
    if (strcmp(result, not_expected) == 0) {
        fprintf(stderr, "FAIL: %s:%d: guarded_realpath followed escaping symlink to %s\n",
                __FILE__, __LINE__, result);
        exit(1);
    }

    /* Result should still be something under sandbox_dir or the link path itself */
    snprintf(path, sizeof(path), "%s/link_out", sandbox_dir);
    ASSERT_STREQ(result, path);
}

TEST(test_guarded_realpath_outside_root) {
    /* Path entirely outside sandbox — guarded_realpath should resolve normally
     * (we only guard symlinks that escape FROM a root, not paths already outside) */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/b.txt", external_dir);

    char resolved[PATH_MAX];
    char *result = guarded_realpath(path, resolved);
    ASSERT_NOT_NULL(result);

    /* Should resolve normally since it's not in any root */
    char expected[PATH_MAX];
    snprintf(expected, sizeof(expected), "%s/b.txt", external_dir);
    ASSERT_STREQ(result, expected);
}

TEST(test_guarded_realpath_nonexistent) {
    /* Non-existent path should return NULL with ENOENT */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/does_not_exist.txt", sandbox_dir);

    errno = 0;
    char *result = guarded_realpath(path, NULL);
    ASSERT_NULL(result);
    ASSERT_EQ(errno, ENOENT);
}

TEST(test_guarded_realpath_null_resolved) {
    /* When resolved_path is NULL, guarded_realpath should allocate the result */
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "%s/a.txt", sandbox_dir);

    char *result = guarded_realpath(path, NULL);
    ASSERT_NOT_NULL(result);

    char expected[PATH_MAX];
    snprintf(expected, sizeof(expected), "%s/a.txt", sandbox_dir);
    ASSERT_STREQ(result, expected);

    free(result);
}

/* --------------------------------------------------------------------------
 * main
 * -------------------------------------------------------------------------- */

int main(void) {
    /* Initialize orig_* function pointers to real libc functions */
    orig_realpath = realpath;
    orig_lstat    = lstat;
    orig_readlink = readlink;

    printf("test_realpath:\n");
    setup();

    RUN_TEST(test_guarded_realpath_regular_file);
    RUN_TEST(test_guarded_realpath_in_root_symlink);
    RUN_TEST(test_guarded_realpath_escaping_symlink);
    RUN_TEST(test_guarded_realpath_outside_root);
    RUN_TEST(test_guarded_realpath_nonexistent);
    RUN_TEST(test_guarded_realpath_null_resolved);

    teardown();

    printf("All tests passed.\n");
    return 0;
}
