#!/usr/bin/env zsh
# =============================================================================
# PolyInstall — Python Installer (macOS, Zsh)
# =============================================================================
# Downloads the official CPython tarball, verifies its SHA-256 checksum,
# extracts it, builds from source, and appends the install prefix to PATH
# in ~/.zshrc and ~/.zprofile.
#
# Usage:
#   chmod +x install.zsh
#   ./install.zsh [--version <x.y.z>] [--prefix <install_dir>]
#
# Defaults:
#   --version   3.13.3
#   --prefix    $HOME/.local/python3
#
# Note: Xcode Command Line Tools must be installed (xcode-select --install).
# =============================================================================

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
PYTHON_VERSION="3.13.3"
INSTALL_PREFIX="$HOME/.local/python3"
DOWNLOAD_DIR="$(mktemp -d)"
JOBS="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 2)"

# ── Colours ───────────────────────────────────────────────────────────────────
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

log()     { print -P "${CYAN}${BOLD}[polyinstall]${RESET} $*" }
success() { print -P "${GREEN}${BOLD}[ok]${RESET} $*" }
error()   { print -P "${RED}${BOLD}[error]${RESET} $*" >&2; exit 1 }

# ── Argument parsing ──────────────────────────────────────────────────────────
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
    if ! command -v "$1" &>/dev/null; then
        error "Required tool not found: $1\n  Install Xcode Command Line Tools: xcode-select --install"
    fi
}

log "Checking dependencies..."
for dep in curl shasum tar make clang; do
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
# macOS uses `shasum -a 256` instead of sha256sum
log "Verifying SHA-256 checksum..."
EXPECTED_HASH="$(awk '{print $1}' "$CHECKSUM_PATH")"
ACTUAL_HASH="$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')"

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

# On Apple Silicon, ensure the SDK path is found
SDKROOT="$(xcrun --show-sdk-path 2>/dev/null || true)"
[[ -n "$SDKROOT" ]] && export SDKROOT

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

add_to_path() {
    local profile="$1"
    if [[ ! -f "$profile" ]] || ! grep -qF "$BIN_DIR" "$profile" 2>/dev/null; then
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

# Zsh reads ~/.zshrc for interactive shells and ~/.zprofile for login shells
add_to_path "$HOME/.zshrc"
add_to_path "$HOME/.zprofile"

# ── Cleanup ───────────────────────────────────────────────────────────────────
log "Cleaning up temporary files..."
rm -rf "$DOWNLOAD_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
success "Python ${PYTHON_VERSION} installed successfully to ${INSTALL_PREFIX}"
print ""
print "  Run: \033[1msource ~/.zshrc\033[0m  (or open a new terminal)"
print "  Then verify with: \033[1mpython3 --version\033[0m"
print ""
