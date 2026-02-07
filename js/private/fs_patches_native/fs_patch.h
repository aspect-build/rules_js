/*
 * fs_patch.h — Native FS sandbox for rules_js
 *
 * Intercepts libc filesystem calls via LD_PRELOAD / DYLD_INSERT_LIBRARIES
 * to prevent Node.js (and especially ESM imports) from escaping the Bazel
 * sandbox / runfiles tree.
 *
 * See: https://github.com/aspect-build/rules_js/issues/362
 */
#ifndef FS_PATCH_H_
#define FS_PATCH_H_

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <stddef.h>
#include <stdio.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

/* Maximum number of sandbox roots (execroot + runfiles + sandbox paths) */
#define FS_PATCH_MAX_ROOTS 16

/* Maximum symlink resolution depth to prevent ELOOP */
#define FS_PATCH_MAX_SYMLINK_DEPTH 256

/* --------------------------------------------------------------------------
 * Configuration
 * -------------------------------------------------------------------------- */

typedef struct {
    char *roots[FS_PATCH_MAX_ROOTS];
    int   num_roots;
    int   enabled;
    int   debug;
} fs_patch_config_t;

extern fs_patch_config_t g_config;

/* --------------------------------------------------------------------------
 * Core logic (fs_patch_common.c)
 * -------------------------------------------------------------------------- */

/* Returns 1 if child is equal to parent or is under parent/ */
int is_sub_path(const char *parent, const char *child);

/* Returns root index (>=0) if link_path is in a root but target_path escapes it.
 * Returns -1 if no escape detected. */
int check_escape(const char *link_path, const char *target_path);

/* Returns 1 if path is under any configured root */
int can_escape(const char *path);

/* Normalize path: resolve . and .. without following symlinks.
 * Input must be absolute. Writes to buf (must be PATH_MAX). Returns buf or NULL. */
char *normalize_path(const char *path, char *buf);

/* Make path absolute: if relative, prepend cwd. Writes to buf. Returns buf or NULL. */
char *make_absolute(const char *path, char *buf);

/* Core guarded realpath: resolves path but stops at sandbox-escaping symlinks.
 * If resolved_path is NULL, allocates result (caller must free).
 * Returns resolved path or NULL on error (sets errno). */
char *guarded_realpath(const char *path, char *resolved_path);

/* --------------------------------------------------------------------------
 * Initialization (fs_patch_init.c)
 * -------------------------------------------------------------------------- */

/* Called automatically via __attribute__((constructor)).
 * Reads env vars, resolves original function pointers. */
void fs_patch_init(void);

/* --------------------------------------------------------------------------
 * Original function pointer typedefs — T1 (realpath) only
 * -------------------------------------------------------------------------- */

typedef char *(*orig_realpath_fn)(const char *restrict, char *restrict);
typedef int   (*orig_lstat_fn)(const char *restrict, struct stat *restrict);
typedef ssize_t (*orig_readlink_fn)(const char *restrict, char *restrict, size_t);

#ifdef __linux__
typedef char *(*orig___realpath_chk_fn)(const char *, char *, size_t);
typedef char *(*orig_canonicalize_file_name_fn)(const char *);
#endif /* __linux__ */

/* --------------------------------------------------------------------------
 * Original function pointer declarations
 * -------------------------------------------------------------------------- */

extern orig_realpath_fn  orig_realpath;
extern orig_lstat_fn     orig_lstat;
extern orig_readlink_fn  orig_readlink;

#ifdef __linux__
extern orig___realpath_chk_fn    orig___realpath_chk;
extern orig_canonicalize_file_name_fn orig_canonicalize_file_name;
#endif /* __linux__ */

/* --------------------------------------------------------------------------
 * Debug logging
 * -------------------------------------------------------------------------- */

#define FS_PATCH_DEBUG(fmt, ...) \
    do { \
        if (g_config.debug) { \
            fprintf(stderr, "DEBUG: fs_patch: " fmt "\n", ##__VA_ARGS__); \
        } \
    } while (0)

#endif /* FS_PATCH_H_ */
