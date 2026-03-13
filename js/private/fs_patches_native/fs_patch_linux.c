#define _GNU_SOURCE
#include "fs_patch.h"
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include <limits.h>

#ifdef __linux__

/* **************************************************************************
 * TIER 1 — realpath interpositions
 * ************************************************************************** */

char *realpath(const char *restrict path, char *restrict resolved_path) {
    if (!g_config.enabled) {
        return orig_realpath(path, resolved_path);
    }
    return guarded_realpath(path, resolved_path);
}

char *__realpath_chk(const char *restrict path, char *restrict resolved_path,
                     size_t resolved_len) {
    if (!g_config.enabled) {
        if (orig___realpath_chk) {
            return orig___realpath_chk(path, resolved_path, resolved_len);
        }
        return orig_realpath(path, resolved_path);
    }
    /* Respect _FORTIFY_SOURCE buffer size check */
    if (resolved_path && resolved_len < PATH_MAX) {
        errno = ERANGE;
        return NULL;
    }
    return guarded_realpath(path, resolved_path);
}

char *canonicalize_file_name(const char *path) {
    if (!g_config.enabled) {
        if (orig_canonicalize_file_name) {
            return orig_canonicalize_file_name(path);
        }
        return orig_realpath(path, NULL);
    }
    return guarded_realpath(path, NULL);
}

#endif /* __linux__ */
