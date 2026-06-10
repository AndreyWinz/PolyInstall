/*
 * =============================================================================
 * PolyInstall — Python Installer (written in C)
 * main.c — Entry point and orchestration
 * =============================================================================
 * Downloads the official CPython source tarball, verifies its SHA-256
 * checksum, extracts it, builds from source, and updates PATH.
 *
 * Supported platforms: Linux, macOS
 * (For Windows, use install.ps1 in the windows/ directory.)
 *
 * Build:
 *   See BUILD.md
 *
 * Usage:
 *   ./polyinstall_python [--version <x.y.z>] [--prefix <dir>]
 * =============================================================================
 */

#include "installer.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── Defaults ────────────────────────────────────────────────────────────── */
#define DEFAULT_VERSION "3.13.3"

/* $HOME/.local/python3 is resolved at runtime */
static void default_prefix(char *out, size_t len) {
    const char *home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "[error] $HOME is not set.\n");
        exit(EXIT_FAILURE);
    }
    snprintf(out, len, "%s/.local/python3", home);
}

/* ── Argument parsing ────────────────────────────────────────────────────── */
static void parse_args(int argc, char **argv,
                        char *version, size_t vlen,
                        char *prefix,  size_t plen) {
    /* Set defaults */
    strncpy(version, DEFAULT_VERSION, vlen - 1);
    version[vlen - 1] = '\0';
    default_prefix(prefix, plen);

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--version") == 0 && i + 1 < argc) {
            strncpy(version, argv[++i], vlen - 1);
            version[vlen - 1] = '\0';
        } else if (strcmp(argv[i], "--prefix") == 0 && i + 1 < argc) {
            strncpy(prefix, argv[++i], plen - 1);
            prefix[plen - 1] = '\0';
        } else {
            fprintf(stderr, "[error] Unknown argument: %s\n", argv[i]);
            fprintf(stderr, "Usage: %s [--version <x.y.z>] [--prefix <dir>]\n", argv[0]);
            exit(EXIT_FAILURE);
        }
    }
}

/* ── Main ────────────────────────────────────────────────────────────────── */
int main(int argc, char **argv) {
    char version[64];
    char prefix[PATH_MAX_LEN];

    parse_args(argc, argv, version, sizeof(version), prefix, sizeof(prefix));

    printf("\n");
    log_info("PolyInstall — Python Installer (C variant)");
    log_info("Version : %s", version);
    log_info("Prefix  : %s", prefix);
    printf("\n");

    /* Step 1 — Check dependencies */
    check_dependencies();

    /* Step 2 — Download tarball and checksum */
    char tarball_path[PATH_MAX_LEN];
    char checksum_path[PATH_MAX_LEN];
    download_python(version, tarball_path, sizeof(tarball_path),
                               checksum_path, sizeof(checksum_path));

    /* Step 3 — Verify checksum */
    verify_checksum(tarball_path, checksum_path);

    /* Step 4 — Extract */
    char source_dir[PATH_MAX_LEN];
    extract_tarball(tarball_path, version, source_dir, sizeof(source_dir));

    /* Step 5 — Build and install */
    build_and_install(source_dir, prefix);

    /* Step 6 — Update PATH in shell profile */
    update_path(prefix);

    /* Step 7 — Cleanup */
    cleanup();

    printf("\n");
    log_ok("Python %s installed successfully to %s", version, prefix);
    printf("  Run:    source ~/.bashrc  (or ~/.zshrc, or open a new terminal)\n");
    printf("  Verify: python3 --version\n\n");

    return EXIT_SUCCESS;
}
