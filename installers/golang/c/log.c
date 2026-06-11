#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "installer.h"

void log_info(const char *fmt, ...) {
    printf("[+] ");
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}

void log_err(const char *fmt, ...) {
    fprintf(stderr, "[-] ERROR: ");
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, args);
    va_end(args);
    fprintf(stderr, "\n");
    exit(1);
}

void log_success(const char *fmt, ...) {
    printf("[*] SUCCESS: ");
    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    printf("\n");
}