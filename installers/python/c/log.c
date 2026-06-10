/*
 * log.c — Logging helpers for the PolyInstall Python C installer
 */

#include "installer.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* ANSI colour codes — disabled automatically if not a TTY */
#define COL_CYAN  "\033[0;36m"
#define COL_GREEN "\033[0;32m"
#define COL_RED   "\033[0;31m"
#define COL_BOLD  "\033[1m"
#define COL_RESET "\033[0m"

static int use_colour = -1;   /* -1 = uninitialised */

static int colours_enabled(void) {
    if (use_colour == -1) {
        /* Enable colour only when stdout/stderr are a terminal */
#ifdef _WIN32
        use_colour = 0;
#else
        #include <unistd.h>
        use_colour = isatty(fileno(stdout));
#endif
    }
    return use_colour;
}

void log_info(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    if (colours_enabled())
        fprintf(stdout, COL_CYAN COL_BOLD "[polyinstall]" COL_RESET " ");
    else
        fprintf(stdout, "[polyinstall] ");
    vfprintf(stdout, fmt, ap);
    fprintf(stdout, "\n");
    va_end(ap);
}

void log_ok(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    if (colours_enabled())
        fprintf(stdout, COL_GREEN COL_BOLD "[ok]" COL_RESET " ");
    else
        fprintf(stdout, "[ok] ");
    vfprintf(stdout, fmt, ap);
    fprintf(stdout, "\n");
    va_end(ap);
}

void log_err(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    if (colours_enabled())
        fprintf(stderr, COL_RED COL_BOLD "[error]" COL_RESET " ");
    else
        fprintf(stderr, "[error] ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    exit(EXIT_FAILURE);
}
