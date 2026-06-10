/*
 * installer.h — Shared declarations for the PolyInstall Python C installer
 */

#ifndef INSTALLER_H
#define INSTALLER_H

#include <stddef.h>

/* ── Constants ────────────────────────────────────────────────────────────── */
#define PATH_MAX_LEN    4096
#define HASH_HEX_LEN    65      /* SHA-256 hex string + null terminator */

/* ── Logging ──────────────────────────────────────────────────────────────── */
void log_info(const char *fmt, ...);
void log_ok  (const char *fmt, ...);
void log_err (const char *fmt, ...);   /* prints to stderr and exits */

/* ── Steps ────────────────────────────────────────────────────────────────── */

/*
 * check_dependencies()
 * Verifies that curl, tar, make, and a C compiler are available on PATH.
 * Calls log_err and exits if any are missing.
 */
void check_dependencies(void);

/*
 * download_python()
 * Downloads the CPython tarball and its SHA-256 checksum file into a
 * temporary directory. Fills tarball_out and checksum_out with their paths.
 */
void download_python(const char *version,
                     char *tarball_out,  size_t tarball_len,
                     char *checksum_out, size_t checksum_len);

/*
 * verify_checksum()
 * Computes the SHA-256 digest of the file at tarball_path and compares
 * it against the hash in checksum_path. Exits on mismatch.
 */
void verify_checksum(const char *tarball_path, const char *checksum_path);

/*
 * extract_tarball()
 * Extracts the tarball into the same directory. Fills source_dir_out with
 * the path of the extracted Python-<version> folder.
 */
void extract_tarball(const char *tarball_path, const char *version,
                     char *source_dir_out, size_t source_dir_len);

/*
 * build_and_install()
 * Runs ./configure, make, and make install inside source_dir,
 * targeting the given prefix.
 */
void build_and_install(const char *source_dir, const char *prefix);

/*
 * update_path()
 * Appends <prefix>/bin to PATH in ~/.bashrc and ~/.zshrc (if present).
 */
void update_path(const char *prefix);

/*
 * cleanup()
 * Removes the temporary download directory created by download_python().
 */
void cleanup(void);

#endif /* INSTALLER_H */
