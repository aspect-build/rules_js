#include "fs_patch.h"

#ifdef __APPLE__

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>

/* **************************************************************************
 * macOS DYLD interpose helpers
 *
 * DYLD __DATA,__interpose causes dlsym(RTLD_NEXT, "lstat") to return the
 * INTERPOSED function (our own my_lstat), leading to infinite recursion.
 * We use fstatat/readlinkat as non-interposed equivalents.
 * ************************************************************************** */

static int real_lstat(const char *path, struct stat *buf) {
    return fstatat(AT_FDCWD, path, buf, AT_SYMLINK_NOFOLLOW);
}

static ssize_t real_readlink(const char *path, char *buf, size_t bufsiz) {
    return readlinkat(AT_FDCWD, path, buf, bufsiz);
}

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
 * TIER 2 — lstat
 *
 * If a symlink inside the sandbox would escape when followed, return stat()
 * data instead (making it look like a regular file). This prevents Node's
 * ESM resolver from following the symlink.
 *
 * On macOS we don't need seccomp BPF — DYLD_INSERT_LIBRARIES directly
 * interposes lstat for all dynamically-linked processes (including esbuild).
 * ************************************************************************** */

static int my_lstat(const char *restrict path, struct stat *restrict buf) {
    /* Use fstatat to avoid recursion — DYLD interposing makes orig_lstat
     * point back to my_lstat, but fstatat is not interposed. */
    int ret = real_lstat(path, buf);
    if (ret != 0 || !g_config.enabled) {
        return ret;
    }

    if (S_ISLNK(buf->st_mode) && can_escape(path)) {
        char target[PATH_MAX];
        ssize_t len = real_readlink(path, target, PATH_MAX - 1);
        if (len > 0) {
            target[len] = '\0';

            char abs_target[PATH_MAX];
            if (target[0] != '/') {
                /* Relative target — resolve against directory containing the symlink */
                char dir[PATH_MAX];
                strncpy(dir, path, PATH_MAX - 1);
                dir[PATH_MAX - 1] = '\0';
                char *slash = strrchr(dir, '/');
                if (slash) {
                    slash[1] = '\0';
                    snprintf(abs_target, PATH_MAX, "%s%s", dir, target);
                } else {
                    strncpy(abs_target, target, PATH_MAX - 1);
                    abs_target[PATH_MAX - 1] = '\0';
                }
            } else {
                strncpy(abs_target, target, PATH_MAX - 1);
                abs_target[PATH_MAX - 1] = '\0';
            }

            char norm[PATH_MAX];
            if (normalize_path(abs_target, norm) && check_escape(path, norm) >= 0) {
                /* Would escape — make it look like a regular file */
                FS_PATCH_DEBUG("lstat: masking symlink escape at %s -> %s", path, norm);
                struct stat real_stat;
                if (fstatat(AT_FDCWD, path, &real_stat, 0) == 0) {
                    *buf = real_stat;
                } else {
                    buf->st_mode = (buf->st_mode & ~S_IFMT) | S_IFREG;
                }
            }
        }
    }

    return ret;
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
    { (const void *)my_lstat,       (const void *)lstat },
};

#endif /* __APPLE__ */
