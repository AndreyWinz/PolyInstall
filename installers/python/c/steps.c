/*
 * steps.c — Installation steps for the PolyInstall Python C installer
 *
 * Covers: dependency checks, download, checksum verification,
 *         extraction, build/install, PATH update, and cleanup.
 */

#include "installer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

/* POSIX */
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

/* ── Module-level temp dir (set by download_python, freed by cleanup) ─────── */
static char g_temp_dir[PATH_MAX_LEN] = {0};

/* ── Internal helpers ────────────────────────────────────────────────────── */

/* Run a shell command via /bin/sh -c; exits on non-zero return. */
static void run_cmd(const char *cmd) {
    int ret = system(cmd);
    if (ret != 0) {
        log_err("Command failed (exit %d): %s", WEXITSTATUS(ret), cmd);
    }
}

/* Run a command and check only that system() itself didn't fail;
   used where we accept a non-zero exit (e.g. `which`). */
static int run_cmd_rc(const char *cmd) {
    int ret = system(cmd);
    return WEXITSTATUS(ret);
}

/* Safely concatenate into a fixed buffer; exits on overflow. */
static void safe_snprintf(char *buf, size_t len, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, len, fmt, ap);
    va_end(ap);
    if (n < 0 || (size_t)n >= len)
        log_err("Internal buffer overflow while building string.");
}

/* ── Step 1: Dependency check ────────────────────────────────────────────── */
void check_dependencies(void) {
    log_info("Checking dependencies...");

    const char *deps[] = { "curl", "tar", "make", NULL };
    /* Accept either gcc or clang */
    int has_compiler = (run_cmd_rc("command -v gcc  >/dev/null 2>&1") == 0 ||
                        run_cmd_rc("command -v clang >/dev/null 2>&1") == 0);

    for (int i = 0; deps[i]; i++) {
        char cmd[256];
        safe_snprintf(cmd, sizeof(cmd),
                      "command -v %s >/dev/null 2>&1", deps[i]);
        if (run_cmd_rc(cmd) != 0)
            log_err("Required tool not found: %s. Please install it and retry.", deps[i]);
    }

    if (!has_compiler)
        log_err("No C compiler found. Please install gcc or clang.");

    log_ok("All dependencies present.");
}

/* ── Step 2: Download ────────────────────────────────────────────────────── */
void download_python(const char *version,
                     char *tarball_out,  size_t tarball_len,
                     char *checksum_out, size_t checksum_len) {

    /* Create a temporary directory */
    strncpy(g_temp_dir, "/tmp/polyinstall_python_XXXXXX", sizeof(g_temp_dir) - 1);
    if (!mkdtemp(g_temp_dir))
        log_err("Failed to create temporary directory: %s", strerror(errno));

    /* Build paths */
    safe_snprintf(tarball_out,  tarball_len,  "%s/Python-%s.tgz",        g_temp_dir, version);
    safe_snprintf(checksum_out, checksum_len, "%s/Python-%s.tgz.sha256", g_temp_dir, version);

    char cmd[PATH_MAX_LEN * 2];

    /* Download tarball */
    log_info("Downloading Python %s...", version);
    safe_snprintf(cmd, sizeof(cmd),
        "curl -fSL --progress-bar "
        "\"https://www.python.org/ftp/python/%s/Python-%s.tgz\" "
        "-o \"%s\"",
        version, version, tarball_out);
    run_cmd(cmd);

    /* Download checksum */
    log_info("Downloading checksum...");
    safe_snprintf(cmd, sizeof(cmd),
        "curl -fSL "
        "\"https://www.python.org/ftp/python/%s/Python-%s.tgz.sha256\" "
        "-o \"%s\"",
        version, version, checksum_out);
    run_cmd(cmd);
}

/* ── Step 3: SHA-256 verification ────────────────────────────────────────── */

/*
 * Minimal SHA-256 implementation.
 * Based on the FIPS 180-4 specification. No external libraries required.
 */

typedef struct {
    uint32_t state[8];
    uint64_t count;
    uint8_t  buf[64];
} sha256_ctx;

static const uint32_t K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,
    0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,
    0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,
    0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,
    0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,
    0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,
    0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,
    0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,
    0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

#define ROTR(x,n) (((x) >> (n)) | ((x) << (32-(n))))
#define CH(x,y,z)  (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define SIG0(x) (ROTR(x,2)  ^ ROTR(x,13) ^ ROTR(x,22))
#define SIG1(x) (ROTR(x,6)  ^ ROTR(x,11) ^ ROTR(x,25))
#define sig0(x) (ROTR(x,7)  ^ ROTR(x,18) ^ ((x) >> 3))
#define sig1(x) (ROTR(x,17) ^ ROTR(x,19) ^ ((x) >> 10))

static void sha256_transform(sha256_ctx *ctx, const uint8_t *data) {
    uint32_t w[64], a, b, c, d, e, f, g, h, t1, t2;
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)data[i*4]     << 24) |
               ((uint32_t)data[i*4 + 1] << 16) |
               ((uint32_t)data[i*4 + 2] <<  8) |
               ((uint32_t)data[i*4 + 3]);
    }
    for (int i = 16; i < 64; i++)
        w[i] = sig1(w[i-2]) + w[i-7] + sig0(w[i-15]) + w[i-16];

    a = ctx->state[0]; b = ctx->state[1];
    c = ctx->state[2]; d = ctx->state[3];
    e = ctx->state[4]; f = ctx->state[5];
    g = ctx->state[6]; h = ctx->state[7];

    for (int i = 0; i < 64; i++) {
        t1 = h + SIG1(e) + CH(e,f,g) + K[i] + w[i];
        t2 = SIG0(a) + MAJ(a,b,c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    ctx->state[0] += a; ctx->state[1] += b;
    ctx->state[2] += c; ctx->state[3] += d;
    ctx->state[4] += e; ctx->state[5] += f;
    ctx->state[6] += g; ctx->state[7] += h;
}

static void sha256_init(sha256_ctx *ctx) {
    ctx->count = 0;
    ctx->state[0] = 0x6a09e667; ctx->state[1] = 0xbb67ae85;
    ctx->state[2] = 0x3c6ef372; ctx->state[3] = 0xa54ff53a;
    ctx->state[4] = 0x510e527f; ctx->state[5] = 0x9b05688c;
    ctx->state[6] = 0x1f83d9ab; ctx->state[7] = 0x5be0cd19;
}

static void sha256_update(sha256_ctx *ctx, const uint8_t *data, size_t len) {
    size_t i = 0;
    uint32_t index = (uint32_t)(ctx->count & 0x3F);
    ctx->count += len;
    while (i < len) {
        ctx->buf[index++] = data[i++];
        if (index == 64) {
            sha256_transform(ctx, ctx->buf);
            index = 0;
        }
    }
}

static void sha256_final(sha256_ctx *ctx, uint8_t digest[32]) {
    uint8_t pad[64] = {0};
    uint32_t index = (uint32_t)(ctx->count & 0x3F);
    pad[0] = 0x80;
    uint64_t bit_count = ctx->count * 8;
    size_t pad_len = (index < 56) ? (56 - index) : (120 - index);
    sha256_update(ctx, pad, pad_len);
    uint8_t len_bytes[8];
    for (int i = 7; i >= 0; i--) {
        len_bytes[i] = (uint8_t)(bit_count & 0xFF);
        bit_count >>= 8;
    }
    sha256_update(ctx, len_bytes, 8);
    for (int i = 0; i < 8; i++) {
        digest[i*4]     = (ctx->state[i] >> 24) & 0xFF;
        digest[i*4 + 1] = (ctx->state[i] >> 16) & 0xFF;
        digest[i*4 + 2] = (ctx->state[i] >>  8) & 0xFF;
        digest[i*4 + 3] =  ctx->state[i]         & 0xFF;
    }
}

static void hash_file(const char *path, char hex_out[HASH_HEX_LEN]) {
    FILE *f = fopen(path, "rb");
    if (!f) log_err("Cannot open file for hashing: %s", path);

    sha256_ctx ctx;
    sha256_init(&ctx);
    uint8_t buf[8192];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0)
        sha256_update(&ctx, buf, n);
    fclose(f);

    uint8_t digest[32];
    sha256_final(&ctx, digest);
    for (int i = 0; i < 32; i++)
        snprintf(hex_out + i * 2, 3, "%02x", digest[i]);
    hex_out[64] = '\0';
}

void verify_checksum(const char *tarball_path, const char *checksum_path) {
    log_info("Verifying SHA-256 checksum...");

    /* Read expected hash (first 64 hex chars of first line) */
    FILE *f = fopen(checksum_path, "r");
    if (!f) log_err("Cannot open checksum file: %s", checksum_path);
    char expected[HASH_HEX_LEN] = {0};
    if (fscanf(f, "%64s", expected) != 1) {
        fclose(f);
        log_err("Failed to read expected checksum from %s", checksum_path);
    }
    fclose(f);

    char actual[HASH_HEX_LEN];
    hash_file(tarball_path, actual);

    if (strcmp(expected, actual) != 0)
        log_err("Checksum mismatch!\n  Expected: %s\n  Got:      %s",
                expected, actual);

    log_ok("Checksum verified: %s", actual);
}

/* ── Step 4: Extract ─────────────────────────────────────────────────────── */
void extract_tarball(const char *tarball_path, const char *version,
                     char *source_dir_out, size_t source_dir_len) {
    log_info("Extracting archive...");

    /* Derive the parent directory from tarball_path */
    char parent[PATH_MAX_LEN];
    strncpy(parent, tarball_path, sizeof(parent) - 1);
    char *slash = strrchr(parent, '/');
    if (slash) *slash = '\0';
    else strncpy(parent, ".", sizeof(parent) - 1);

    char cmd[PATH_MAX_LEN * 2];
    safe_snprintf(cmd, sizeof(cmd), "tar -xzf \"%s\" -C \"%s\"",
                  tarball_path, parent);
    run_cmd(cmd);

    safe_snprintf(source_dir_out, source_dir_len,
                  "%s/Python-%s", parent, version);
    log_ok("Extracted to %s", source_dir_out);
}

/* ── Step 5: Build and install ───────────────────────────────────────────── */
void build_and_install(const char *source_dir, const char *prefix) {
    /* Detect logical CPU count for parallel make */
    int jobs = 2;
#if defined(__linux__)
    jobs = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (jobs < 1) jobs = 2;
#elif defined(__APPLE__)
    /* macOS: use sysctl */
    {
        char buf[16];
        FILE *p = popen("sysctl -n hw.logicalcpu 2>/dev/null", "r");
        if (p) {
            if (fgets(buf, sizeof(buf), p)) jobs = atoi(buf);
            pclose(p);
        }
    }
#endif

    char cmd[PATH_MAX_LEN * 2];

    log_info("Configuring build (prefix: %s)...", prefix);
    safe_snprintf(cmd, sizeof(cmd),
        "cd \"%s\" && ./configure "
        "--prefix=\"%s\" "
        "--enable-optimizations "
        "--with-ensurepip=install "
        "--quiet",
        source_dir, prefix);
    run_cmd(cmd);

    log_info("Building Python (using %d jobs — this may take several minutes)...", jobs);
    safe_snprintf(cmd, sizeof(cmd),
        "cd \"%s\" && make -j%d --quiet", source_dir, jobs);
    run_cmd(cmd);

    log_info("Installing to %s...", prefix);
    safe_snprintf(cmd, sizeof(cmd),
        "cd \"%s\" && make install --quiet", source_dir);
    run_cmd(cmd);

    log_ok("Build and install complete.");
}

/* ── Step 6: Update PATH ─────────────────────────────────────────────────── */

static void append_path_to_profile(const char *profile, const char *bin_dir,
                                    const char *version) {
    /* Check if already present */
    char check_cmd[PATH_MAX_LEN * 2];
    safe_snprintf(check_cmd, sizeof(check_cmd),
                  "grep -qF \"%s\" \"%s\" 2>/dev/null", bin_dir, profile);
    if (run_cmd_rc(check_cmd) == 0) {
        log_info("PATH already contains %s in %s, skipping.", bin_dir, profile);
        return;
    }

    FILE *f = fopen(profile, "a");
    if (!f) {
        log_info("Warning: could not open %s for writing, skipping.", profile);
        return;
    }
    fprintf(f, "\n# Added by PolyInstall — Python %s\n", version);
    fprintf(f, "export PATH=\"%s:$PATH\"\n", bin_dir);
    fclose(f);
    log_info("PATH updated in %s", profile);
}

void update_path(const char *prefix) {
    const char *home = getenv("HOME");
    if (!home) { log_info("Warning: $HOME not set, skipping PATH update."); return; }

    char bin_dir[PATH_MAX_LEN];
    safe_snprintf(bin_dir, sizeof(bin_dir), "%s/bin", prefix);

    /* Detect Python version string from the prefix path for the comment */
    /* (We don't have the version at this point as a separate param, so use a generic label) */
    const char *version_label = "3.x";

    char bashrc[PATH_MAX_LEN], zshrc[PATH_MAX_LEN], zprofile[PATH_MAX_LEN];
    safe_snprintf(bashrc,   sizeof(bashrc),   "%s/.bashrc",   home);
    safe_snprintf(zshrc,    sizeof(zshrc),    "%s/.zshrc",    home);
    safe_snprintf(zprofile, sizeof(zprofile), "%s/.zprofile", home);

    append_path_to_profile(bashrc,   bin_dir, version_label);

    /* Only update Zsh files if they already exist */
    struct stat st;
    if (stat(zshrc,    &st) == 0) append_path_to_profile(zshrc,    bin_dir, version_label);
    if (stat(zprofile, &st) == 0) append_path_to_profile(zprofile, bin_dir, version_label);

    log_ok("PATH update complete.");
}

/* ── Step 7: Cleanup ─────────────────────────────────────────────────────── */
void cleanup(void) {
    if (g_temp_dir[0] == '\0') return;
    log_info("Cleaning up temporary files...");
    char cmd[PATH_MAX_LEN + 32];
    safe_snprintf(cmd, sizeof(cmd), "rm -rf \"%s\"", g_temp_dir);
    run_cmd(cmd);
    g_temp_dir[0] = '\0';
}
