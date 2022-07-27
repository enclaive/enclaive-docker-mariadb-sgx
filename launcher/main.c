//#define DEBUG

#include <libtar.h>
#include <zlib.h>
#include <fcntl.h>
#include <stdio.h>

#ifdef DEBUG
#define APP_PATH "/usr/bin/env"
#else
#define APP_PATH "/app/mariadbd"
#endif

#define OUTPUT_DIR "/var/lib/mysql"
#define OUTPUT_TEST "/var/lib/mysql/mysql_upgrade_info"
#define ARCHIVE_FILE "/app/mysql.tar.gz"

static gzFile openFile = NULL;

static int wrap_gzopen(const char *filename, int flags, ...) {
    if (openFile != NULL) return -1;

    int fd = open(filename, flags);
    openFile = gzdopen(fd, "rb");
    return fd;
}

static int wrap_gzclose(int fd) {
    if (openFile == NULL) return -1;

    return gzclose(openFile);
}

static ssize_t wrap_gzread(int fd, void *buf, size_t count) {
    if (openFile == NULL) return -1;

    return gzread(openFile, buf, count);
}

static ssize_t wrap_gzwrite(int fd, const void *buf, size_t count) {
    if (openFile == NULL) return -1;

    return gzwrite(openFile, (void*) buf, count);
}

static tartype_t zlibtype = { wrap_gzopen, wrap_gzclose, wrap_gzread, wrap_gzwrite };

static int extract(void) {
    TAR *tar;

    if (tar_open(&tar, ARCHIVE_FILE, &zlibtype, O_RDONLY, 0, TAR_GNU) == -1) {
        return -1;
    } else if (tar_extract_all(tar, OUTPUT_DIR) == -1) {
        return -1;
    } else if (tar_close(tar) == -1) {
        return -1;
    }

    return 0;
}

static void error(char *message) {
    fprintf(stderr, "[middlemain] %s \n", message);
}

int main(int argc, char *argv[]) {
    // only extract if not already existent
    if (access(OUTPUT_TEST, F_OK) == -1) {
        if (extract() == -1) {
            error("Extraction failed");
            return -1;
        // verify that the test file is actually created
        } else if (access(OUTPUT_TEST, F_OK) == -1) {
            error("Access test file failed");
            return -1;
        }
    }

#ifdef DEBUG
    printf("ARGC: %d\n", argc);
    for (int i = 0; i < argc; i++) {
        printf("ARGV[%d]: %s\n", i, argv[i]);
    }
    fflush(stdout);
#endif

    // we could just use argv[0] instead of APP_PATH
    // but then we would always need to run the premain
    argv[0] = APP_PATH;

    return execv(argv[0], argv);
}
