#ifndef INSTALLER_H
#define INSTALLER_H

#include <stddef.h>

#define GO_VERSION "1.26.1"

void log_info(const char *fmt, ...);
void log_err(const char *fmt, ...);
void log_success(const char *fmt, ...);

int download_file(const char *url, const char *dest);
int verify_sha256(const char *filepath, const char *expected_hash);
int extract_archive(const char *archive_path, const char *target_dir);
int update_environment(const char *install_path);

#endif