#define _GNU_SOURCE
#include "fs_patch.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <dlfcn.h>
#include <limits.h>

/* Global config instance (zero-initialized) */
fs_patch_config_t g_config = {0};

/* --------------------------------------------------------------------------
 * Original function pointers — T1 (realpath) only
 * -------------------------------------------------------------------------- */

orig_realpath_fn  orig_realpath  = NULL;
orig_lstat_fn     orig_lstat     = NULL;
orig_readlink_fn  orig_readlink  = NULL;

#ifdef __linux__
orig___realpath_chk_fn    orig___realpath_chk    = NULL;
orig_canonicalize_file_name_fn orig_canonicalize_file_name = NULL;
#endif /* __linux__ */

/* --------------------------------------------------------------------------
 * resolve_originals — resolve all original function pointers via dlsym
 * -------------------------------------------------------------------------- */

static void resolve_originals(void) {
    orig_realpath  = (orig_realpath_fn)dlsym(RTLD_NEXT, "realpath");
    orig_lstat     = (orig_lstat_fn)dlsym(RTLD_NEXT, "lstat");
    orig_readlink  = (orig_readlink_fn)dlsym(RTLD_NEXT, "readlink");

    if (!orig_realpath || !orig_lstat || !orig_readlink) {
        fprintf(stderr,
                "rules_js fs_patch: FATAL: failed to resolve core libc functions\n");
        abort();
    }

#ifdef __linux__
    orig___realpath_chk    = (orig___realpath_chk_fn)dlsym(RTLD_NEXT, "__realpath_chk");
    orig_canonicalize_file_name = (orig_canonicalize_file_name_fn)dlsym(RTLD_NEXT, "canonicalize_file_name");
#endif /* __linux__ */
}

/* --------------------------------------------------------------------------
 * parse_roots — split colon-separated roots, resolve, sort longest-first
 * -------------------------------------------------------------------------- */

static void parse_roots(const char *roots_env) {
    if (!roots_env || !*roots_env) {
        g_config.num_roots = 0;
        return;
    }

    char *roots_copy = strdup(roots_env);
    if (!roots_copy) {
        fprintf(stderr, "rules_js fs_patch: failed to allocate memory for roots\n");
        return;
    }

    char *saveptr = NULL;
    char *token = strtok_r(roots_copy, ":", &saveptr);
    int count = 0;

    while (token) {
        if (count >= FS_PATCH_MAX_ROOTS) {
            fprintf(stderr, "rules_js fs_patch: WARNING: more than %d roots configured, extras ignored\n",
                    FS_PATCH_MAX_ROOTS);
            break;
        }
        if (*token == '\0') {
            token = strtok_r(NULL, ":", &saveptr);
            continue;
        }

        char resolved[PATH_MAX];
        if (orig_realpath(token, resolved)) {
            /* Strip trailing slash (unless it's the root "/") */
            size_t len = strlen(resolved);
            if (len > 1 && resolved[len - 1] == '/') {
                resolved[len - 1] = '\0';
            }

            g_config.roots[count] = strdup(resolved);
            if (g_config.roots[count]) {
                count++;
            }
        } else {
            /* Root path doesn't exist — skip (matches JS: roots.filter(existsSync)) */
            FS_PATCH_DEBUG("skipping non-existent root: %s", token);
        }

        token = strtok_r(NULL, ":", &saveptr);
    }

    g_config.num_roots = count;
    free(roots_copy);

    /* Sort roots by length, longest first (most-specific match wins) */
    for (int i = 0; i < count - 1; i++) {
        for (int j = i + 1; j < count; j++) {
            if (strlen(g_config.roots[j]) > strlen(g_config.roots[i])) {
                char *tmp = g_config.roots[i];
                g_config.roots[i] = g_config.roots[j];
                g_config.roots[j] = tmp;
            }
        }
    }
}

/* --------------------------------------------------------------------------
 * fs_patch_init — library constructor
 * -------------------------------------------------------------------------- */

__attribute__((constructor))
void fs_patch_init(void) {
    /* Resolve original function pointers FIRST — before anything else */
    resolve_originals();

    /* Check if patching is enabled */
    const char *patch_enabled = getenv("JS_BINARY__PATCH_NODE_FS");
    if (!patch_enabled || strcmp(patch_enabled, "0") == 0) {
        g_config.enabled = 0;
        return;
    }

    /* Check for debug logging */
    const char *debug_env = getenv("JS_BINARY__LOG_DEBUG");
    g_config.debug = (debug_env && *debug_env) ? 1 : 0;

    /* Parse roots */
    const char *roots_env = getenv("JS_BINARY__FS_PATCH_ROOTS");
    parse_roots(roots_env);

    if (g_config.num_roots == 0) {
        FS_PATCH_DEBUG("no valid roots found, disabling patches");
        g_config.enabled = 0;
        return;
    }

    g_config.enabled = 1;

    if (g_config.debug) {
        fprintf(stderr, "DEBUG: fs_patch: native library initialized with %d roots:\n",
                g_config.num_roots);
        for (int i = 0; i < g_config.num_roots; i++) {
            fprintf(stderr, "DEBUG: fs_patch:   root[%d]: %s\n",
                    i, g_config.roots[i]);
        }
    }
}
