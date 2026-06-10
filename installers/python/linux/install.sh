#!/usr/bin/env bash
# =============================================================================
# PolyInstall — Python Installer (Linux, Bash)
# =============================================================================
# Downloads the official CPython tarball, verifies its SHA-256 checksum,
# extracts it, builds from source, and appends the install prefix to PATH
# in the user's shell profile.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh [--version <x.y.z>] [--prefix <install_dir>]
#
# Defaults:
#   --version   3.13.3
#   --prefix    $HOME/.local/python3
# =============================================================================

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
PYTHON_VERSION="3.13.3"
INSTALL_PREFIX="$HOME/.local/python3"
DOWNLOAD_DIR="$(mktemp -d)"
JOBS="$(nproc 2>/dev/null || echo 2)"

# ── Colours ──────────────────────────────────────────────────────────────────
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

log()     { echo -e "${CYAN}${BOLD}[polyinstall]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[ok]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[error]${RESET} $*" >&2; exit 1; }

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) PYTHON_VERSION="$2"; shift 2 ;;
        --prefix)  INSTALL_PREFIX="$2"; shift 2 ;;
        *) error "Unknown argument: $1" ;;
    esac
done

# ── Derived variables ─────────────────────────────────────────────────────────
TARBALL="Python-${PYTHON_VERSION}.tgz"
BASE_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}"
TARBALL_URL="${BASE_URL}/${TARBALL}"
CHECKSUM_URL="${BASE_URL}/${TARBALL}.sha256"
TARBALL_PATH="${DOWNLOAD_DIR}/${TARBALL}"
CHECKSUM_PATH="${DOWNLOAD_DIR}/${TARBALL}.sha256"

# ── Dependency check ──────────────────────────────────────────────────────────
check_dep() {
    command -v "$1" &>/dev/null || error "Required tool not found: $1. Please install it and retry."
}

log "Checking dependencies..."
for dep in curl sha256sum tar make gcc; do
    check_dep "$dep"
done
success "All dependencies present."

# ── Download ──────────────────────────────────────────────────────────────────
log "Downloading Python ${PYTHON_VERSION}..."
curl -fSL --progress-bar "$TARBALL_URL" -o "$TARBALL_PATH" \
    || error "Failed to download tarball from ${TARBALL_URL}"

log "Downloading checksum..."
curl -fSL "$CHECKSUM_URL" -o "$CHECKSUM_PATH" \
    || error "Failed to download checksum from ${CHECKSUM_URL}"

# ── Checksum verification ─────────────────────────────────────────────────────
log "Verifying SHA-256 checksum..."
EXPECTED_HASH="$(awk '{print $1}' "$CHECKSUM_PATH")"
ACTUAL_HASH="$(sha256sum "$TARBALL_PATH" | awk '{print $1}')"

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
    error "Checksum mismatch!\n  Expected: ${EXPECTED_HASH}\n  Got:      ${ACTUAL_HASH}"
fi
success "Checksum verified: ${ACTUAL_HASH}"

# ── Extract ───────────────────────────────────────────────────────────────────
log "Extracting archive..."
tar -xzf "$TARBALL_PATH" -C "$DOWNLOAD_DIR" \
    || error "Failed to extract tarball."
SOURCE_DIR="${DOWNLOAD_DIR}/Python-${PYTHON_VERSION}"

# ── Build & install ───────────────────────────────────────────────────────────
log "Configuring build (prefix: ${INSTALL_PREFIX})..."
cd "$SOURCE_DIR"
./configure \
    --prefix="$INSTALL_PREFIX" \
    --enable-optimizations \
    --with-ensurepip=install \
    --quiet \
    || error "Configure step failed."

log "Building Python (this may take a few minutes, using ${JOBS} jobs)..."
make -j"$JOBS" --quiet || error "Build failed."

log "Installing to ${INSTALL_PREFIX}..."
make install --quiet || error "Install step failed."

# ── PATH setup ────────────────────────────────────────────────────────────────
BIN_DIR="${INSTALL_PREFIX}/bin"
PROFILE_FILE="$HOME/.bashrc"

# Also append to .bash_profile if it exists and is not the same file
[[ -f "$HOME/.bash_profile" && "$HOME/.bash_profile" != "$PROFILE_FILE" ]] \
    && EXTRA_PROFILE="$HOME/.bash_profile"

add_to_path() {
    local profile="$1"
    if ! grep -qF "$BIN_DIR" "$profile" 2>/dev/null; then
        {
            echo ""
            echo "# Added by PolyInstall — Python ${PYTHON_VERSION}"
            echo "export PATH=\"${BIN_DIR}:\$PATH\""
        } >> "$profile"
        log "PATH updated in ${profile}"
    else
        log "PATH already contains ${BIN_DIR} in ${profile}, skipping."
    fi
}

add_to_path "$PROFILE_FILE"
[[ -n "${EXTRA_PROFILE:-}" ]] && add_to_path "$EXTRA_PROFILE"

# ── Cleanup ───────────────────────────────────────────────────────────────────
log "Cleaning up temporary files..."
rm -rf "$DOWNLOAD_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
success "Python ${PYTHON_VERSION} installed successfully to ${INSTALL_PREFIX}"
echo -e "\n  Run: ${BOLD}source ~/.bashrc${RESET}  (or open a new terminal)"
echo -e "  Then verify with: ${BOLD}python3 --version${RESET}\n"
