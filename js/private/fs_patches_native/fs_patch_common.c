#define _GNU_SOURCE
#include "fs_patch.h"
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>

/* ==========================================================================
 * is_sub_path — string prefix check with boundary awareness
 * ========================================================================== */

int is_sub_path(const char *parent, const char *child) {
    size_t parent_len = strlen(parent);
    size_t child_len = strlen(child);

    if (parent_len > child_len) {
        return 0;
    }

    if (strncmp(parent, child, parent_len) != 0) {
        return 0;
    }

    /* Exact match */
    if (parent_len == child_len) {
        return 1;
    }

    /* Root "/" is parent of everything */
    if (parent_len == 1 && parent[0] == '/') {
        return 1;
    }

    /* child must have '/' right after parent prefix
     * (prevents "/a/bc" matching parent "/a/b") */
    return child[parent_len] == '/';
}

/* ==========================================================================
 * check_escape — does following link_path -> target_path escape a root?
 * ========================================================================== */

int check_escape(const char *link_path, const char *target_path) {
    for (int i = 0; i < g_config.num_roots; i++) {
        if (is_sub_path(g_config.roots[i], link_path) &&
            !is_sub_path(g_config.roots[i], target_path)) {
            return i;
        }
    }
    return -1;
}

/* ==========================================================================
 * can_escape — is path under any configured root?
 * ========================================================================== */

int can_escape(const char *path) {
    for (int i = 0; i < g_config.num_roots; i++) {
        if (is_sub_path(g_config.roots[i], path)) {
            return 1;
        }
    }
    return 0;
}

/* ==========================================================================
 * normalize_path — resolve . and .. without following symlinks
 * ========================================================================== */

char *normalize_path(const char *path, char *buf) {
    if (!path || path[0] != '/') {
        return NULL;
    }

    size_t path_len = strlen(path);
    if (path_len >= PATH_MAX) {
        return NULL;
    }

    /* Tokenize a copy */
    char tmp[PATH_MAX];
    memcpy(tmp, path, path_len + 1);

    const char *components[PATH_MAX / 2];
    int depth = 0;

    char *saveptr = NULL;
    char *token = strtok_r(tmp, "/", &saveptr);
    while (token) {
        if (token[0] == '.' && token[1] == '\0') {
            /* skip "." */
        } else if (token[0] == '.' && token[1] == '.' && token[2] == '\0') {
            if (depth > 0) depth--;
        } else {
            components[depth++] = token;
        }
        token = strtok_r(NULL, "/", &saveptr);
    }

    /* Reconstruct */
    if (depth == 0) {
        buf[0] = '/';
        buf[1] = '\0';
        return buf;
    }

    char *p = buf;
    for (int i = 0; i < depth; i++) {
        *p++ = '/';
        size_t clen = strlen(components[i]);
        memcpy(p, components[i], clen);
        p += clen;
    }
    *p = '\0';

    return buf;
}

/* ==========================================================================
 * make_absolute — prepend cwd if path is relative
 * ========================================================================== */

char *make_absolute(const char *path, char *buf) {
    if (!path) {
        return NULL;
    }

    if (path[0] == '/') {
        size_t len = strlen(path);
        if (len >= PATH_MAX) {
            errno = ENAMETOOLONG;
            return NULL;
        }
        memcpy(buf, path, len + 1);
        return buf;
    }

    /* Relative — prepend cwd */
    char cwd[PATH_MAX];
    if (!getcwd(cwd, PATH_MAX)) {
        return NULL;
    }

    size_t cwd_len = strlen(cwd);
    size_t path_len = strlen(path);

    if (cwd_len + 1 + path_len >= PATH_MAX) {
        errno = ENAMETOOLONG;
        return NULL;
    }

    memcpy(buf, cwd, cwd_len);
    buf[cwd_len] = '/';
    memcpy(buf + cwd_len + 1, path, path_len + 1);
    return buf;
}

/* ==========================================================================
 * guarded_realpath — THE CORE ALGORITHM
 *
 * Resolves path but stops following symlinks that escape the sandbox.
 *
 * Strategy:
 *   1. Make path absolute, normalize it
 *   2. Fast path: call orig_realpath(); if no escape, return it
 *   3. Slow path: walk component-by-component with lstat+readlink,
 *      stopping at the first symlink hop that escapes a root
 * ========================================================================== */

char *guarded_realpath(const char *path, char *resolved_path) {
    if (!g_config.enabled) {
        return orig_realpath(path, resolved_path);
    }

    /* Make path absolute */
    char abs_input[PATH_MAX];
    if (!make_absolute(path, abs_input)) {
        /* ENAMETOOLONG already set by make_absolute, or getcwd failed */
        if (errno != ENAMETOOLONG) {
            return orig_realpath(path, resolved_path);
        }
        return NULL;
    }

    /* Normalize (resolve . and ..) */
    char norm_input[PATH_MAX];
    if (!normalize_path(abs_input, norm_input)) {
        return orig_realpath(path, resolved_path);
    }

    /* Fast path: try real realpath first */
    int saved_errno = errno;
    char real_resolved[PATH_MAX];
    char *result = orig_realpath(path, real_resolved);
    if (result) {
        int escaped_root = check_escape(norm_input, real_resolved);
        if (escaped_root < 0) {
            /* No escape — return the real resolved path */
            errno = saved_errno;
            if (resolved_path) {
                memcpy(resolved_path, real_resolved, strlen(real_resolved) + 1);
                return resolved_path;
            } else {
                return strdup(real_resolved);
            }
        }
        /* Escape detected — fall through to slow path */
    } else {
        /* orig_realpath failed (e.g., ENOENT for a dangling symlink or
         * non-existent path). We still need to handle this — fall through
         * to the slow path which can handle partially-resolvable paths. */
        if (errno == ENOENT || errno == EACCES) {
            /* These are expected — proceed to slow path */
        } else {
            /* Unexpected error — propagate it */
            return NULL;
        }
    }

    /* ---- Slow path: component-by-component walk ---- */
    char current[PATH_MAX];
    current[0] = '/';
    current[1] = '\0';

    /* We need a mutable copy for tokenization */
    char remaining[PATH_MAX];
    memcpy(remaining, norm_input, strlen(norm_input) + 1);

    char *saveptr = NULL;
    /* Skip leading '/' by starting at remaining+1 */
    char *component = strtok_r(remaining + 1, "/", &saveptr);

    int loop_count = 0;

    while (component) {
        if (++loop_count > FS_PATCH_MAX_SYMLINK_DEPTH) {
            errno = ELOOP;
            return NULL;
        }

        /* Build the next path */
        char next[PATH_MAX];
        if (current[0] == '/' && current[1] == '\0') {
            snprintf(next, PATH_MAX, "/%s", component);
        } else {
            snprintf(next, PATH_MAX, "%s/%s", current, component);
        }

        struct stat st;
        if (orig_lstat(next, &st) != 0) {
            /* Component doesn't exist.
             * If there are remaining components, it's ENOENT.
             * But we still need to return the path up to here
             * with the remaining tail for the caller. */
            char *rest = strtok_r(NULL, "", &saveptr);
            if (rest && *rest) {
                /* Append remaining path after the non-existent component */
                char full[PATH_MAX];
                snprintf(full, PATH_MAX, "%s/%s", next, rest);
                char normed[PATH_MAX];
                if (normalize_path(full, normed)) {
                    if (resolved_path) {
                        memcpy(resolved_path, normed, strlen(normed) + 1);
                        return resolved_path;
                    } else {
                        return strdup(normed);
                    }
                }
            }
            errno = ENOENT;
            return NULL;
        }

        if (S_ISLNK(st.st_mode)) {
            char link_target[PATH_MAX];
            ssize_t link_len = orig_readlink(next, link_target, PATH_MAX - 1);
            if (link_len < 0) {
                errno = ENOENT;
                return NULL;
            }
            link_target[link_len] = '\0';

            /* Make symlink target absolute */
            char abs_target[PATH_MAX];
            if (link_target[0] != '/') {
                /* Relative to directory containing the symlink */
                snprintf(abs_target, PATH_MAX, "%s/%s", current, link_target);
            } else {
                memcpy(abs_target, link_target, link_len + 1);
            }

            char norm_target[PATH_MAX];
            if (!normalize_path(abs_target, norm_target)) {
                errno = EINVAL;
                return NULL;
            }

            if (check_escape(next, norm_target) >= 0) {
                /* This hop escapes! Stop here — return symlink path + remaining */
                FS_PATCH_DEBUG("guarded_realpath: escape at %s -> %s",
                               next, norm_target);

                char *rest = strtok_r(NULL, "", &saveptr);
                char final[PATH_MAX];
                if (rest && *rest) {
                    snprintf(final, PATH_MAX, "%s/%s", next, rest);
                    char renorm[PATH_MAX];
                    if (normalize_path(final, renorm)) {
                        memcpy(final, renorm, strlen(renorm) + 1);
                    }
                } else {
                    memcpy(final, next, strlen(next) + 1);
                }

                if (resolved_path) {
                    memcpy(resolved_path, final, strlen(final) + 1);
                    return resolved_path;
                } else {
                    return strdup(final);
                }
            }

            /* Non-escaping symlink — follow it */
            memcpy(current, norm_target, strlen(norm_target) + 1);
        } else {
            /* Regular file or directory — just advance */
            memcpy(current, next, strlen(next) + 1);
        }

        component = strtok_r(NULL, "/", &saveptr);
    }

    /* Reached the end without escaping */
    if (resolved_path) {
        memcpy(resolved_path, current, strlen(current) + 1);
        return resolved_path;
    } else {
        return strdup(current);
    }
}

