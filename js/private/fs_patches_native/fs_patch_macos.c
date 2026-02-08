#include "fs_patch.h"

#ifdef __APPLE__

#include <stdlib.h>
#include <stdio.h>

/* **************************************************************************
 * TIER 1 — realpath
 * ************************************************************************** */

static char *my_realpath(const char *restrict path,
                         char *restrict resolved_path) {
    if (!g_config.enabled) {
        return orig_realpath(path, resolved_path);
    }
    return guarded_realpath(path, resolved_path);
}

/* **************************************************************************
 * DYLD_INSERT_LIBRARIES interpose section
 * ************************************************************************** */

typedef struct {
    const void *replacement;
    const void *replacee;
} interpose_t;

__attribute__((used))
static const interpose_t interposers[]
    __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_realpath,    (const void *)realpath },
};

#endif /* __APPLE__ */
