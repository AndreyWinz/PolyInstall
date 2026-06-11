#!/usr/bin/env bash
# =============================================================================
# PolyInstall — C++ Installer (Linux, Bash)
# =============================================================================
# Downloads the official GCC source tarball, verifies its SHA-512 checksum,
# extracts it, builds GCC with C and C++ language support from source, and
# appends the install prefix to PATH in the user's shell profile.
#
# GCC is built with --enable-languages=c,c++ so that both gcc and g++ are
# produced in a single build. C support is included because the C++ frontend
# depends on it.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh [--version <x.y.z>] [--prefix <install_dir>]
#
# Defaults:
#   --version   14.2.0
#   --prefix    $HOME/.local/gcc-cpp
#
# Note: Building GCC from source takes 20–60 minutes depending on hardware.
#   A pre-existing system C compiler is required to bootstrap the build.
# =============================================================================

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
GCC_VERSION="14.2.0"
INSTALL_PREFIX="$HOME/.local/gcc-cpp"
DOWNLOAD_DIR="$(mktemp -d)"
JOBS="$(nproc 2>/dev/null || echo 2)"

# ── Colours ───────────────────────────────────────────────────────────────────
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

log()     { echo -e "${CYAN}${BOLD}[polyinstall]${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}[ok]${RESET} $*"; }
error()   { echo -e "${RED}${BOLD}[error]${RESET} $*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) GCC_VERSION="$2"; shift 2 ;;
        --prefix)  INSTALL_PREFIX="$2"; shift 2 ;;
        *) error "Unknown argument: $1" ;;
    esac
done

# ── Derived variables ─────────────────────────────────────────────────────────
TARBALL="gcc-${GCC_VERSION}.tar.xz"
BASE_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}"
TARBALL_URL="${BASE_URL}/${TARBALL}"
SHA512_URL="${BASE_URL}/sha512.sum"
TARBALL_PATH="${DOWNLOAD_DIR}/${TARBALL}"
SHA512_PATH="${DOWNLOAD_DIR}/sha512.sum"
SOURCE_DIR="${DOWNLOAD_DIR}/gcc-${GCC_VERSION}"
BUILD_DIR="${DOWNLOAD_DIR}/gcc-build"

# ── Dependency check ──────────────────────────────────────────────────────────
check_dep() {
    command -v "$1" &>/dev/null \
        || error "Required tool not found: $1. Please install it and retry."
}

log "Checking dependencies..."
for dep in curl sha512sum tar make cc; do
    check_dep "$dep"
done

# Soft-warn on missing math libraries; ./contrib/download_prerequisites
# will fetch them from source, but it is faster if they exist system-wide.
for pkg in libgmp-dev libmpfr-dev libmpc-dev; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q '^ii' && \
       ! rpm -q "${pkg%-dev}" 2>/dev/null | grep -q "${pkg%-dev}"; then
        log "Warning: $pkg may not be installed (will be fetched from source if missing)."
        log "  On Debian/Ubuntu: sudo apt install libgmp-dev libmpfr-dev libmpc-dev"
        log "  On Fedora/RHEL:   sudo dnf install gmp-devel mpfr-devel libmpc-devel"
    fi
done

success "Core dependencies present."

# ── Download ──────────────────────────────────────────────────────────────────
log "Downloading GCC ${GCC_VERSION}..."
curl -fSL --progress-bar "$TARBALL_URL" -o "$TARBALL_PATH" \
    || error "Failed to download tarball from ${TARBALL_URL}"

log "Downloading SHA-512 sums..."
curl -fSL "$SHA512_URL" -o "$SHA512_PATH" \
    || error "Failed to download checksum file from ${SHA512_URL}"

# ── Checksum verification ─────────────────────────────────────────────────────
log "Verifying SHA-512 checksum..."
EXPECTED_HASH="$(grep "${TARBALL}$" "$SHA512_PATH" | awk '{print $1}')"

if [[ -z "$EXPECTED_HASH" ]]; then
    error "Could not find checksum for ${TARBALL} in sha512.sum."
fi

ACTUAL_HASH="$(sha512sum "$TARBALL_PATH" | awk '{print $1}')"

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
    error "Checksum mismatch!\n  Expected: ${EXPECTED_HASH}\n  Got:      ${ACTUAL_HASH}"
fi
success "Checksum verified."

# ── Extract ───────────────────────────────────────────────────────────────────
log "Extracting archive (this may take a moment)..."
tar -xJf "$TARBALL_PATH" -C "$DOWNLOAD_DIR" \
    || error "Failed to extract tarball."
success "Extracted to ${SOURCE_DIR}"

# ── Download GCC prerequisites ────────────────────────────────────────────────
log "Downloading GCC prerequisites (GMP, MPFR, MPC)..."
cd "$SOURCE_DIR"
./contrib/download_prerequisites \
    || error "Failed to download GCC prerequisites."
success "Prerequisites ready."

# ── Configure ─────────────────────────────────────────────────────────────────
# Key difference from the C-only installer: --enable-languages=c,c++
log "Configuring GCC build (prefix: ${INSTALL_PREFIX}, languages: c,c++)..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

"${SOURCE_DIR}/configure" \
    --prefix="$INSTALL_PREFIX" \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-bootstrap \
    --quiet \
    || error "Configure step failed."

# ── Build ─────────────────────────────────────────────────────────────────────
log "Building GCC (using ${JOBS} jobs — this will take a while)..."
make -j"$JOBS" --quiet || error "Build failed."

# ── Install ───────────────────────────────────────────────────────────────────
log "Installing to ${INSTALL_PREFIX}..."
make install --quiet || error "Install step failed."
success "GCC ${GCC_VERSION} (C + C++) built and installed."

# ── PATH setup ────────────────────────────────────────────────────────────────
BIN_DIR="${INSTALL_PREFIX}/bin"
LIB_DIR="${INSTALL_PREFIX}/lib64"

add_to_profile() {
    local profile="$1"
    if ! grep -qF "$BIN_DIR" "$profile" 2>/dev/null; then
        {
            echo ""
            echo "# Added by PolyInstall — GCC ${GCC_VERSION} (C++)"
            echo "export PATH=\"${BIN_DIR}:\$PATH\""
            echo "export LD_LIBRARY_PATH=\"${LIB_DIR}:\${LD_LIBRARY_PATH:-}\""
        } >> "$profile"
        log "Profile updated: ${profile}"
    else
        log "Already configured in ${profile}, skipping."
    fi
}

add_to_profile "$HOME/.bashrc"
[[ -f "$HOME/.bash_profile" ]] && add_to_profile "$HOME/.bash_profile"

# ── Cleanup ───────────────────────────────────────────────────────────────────
log "Cleaning up temporary files..."
rm -rf "$DOWNLOAD_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
success "C++ (GCC ${GCC_VERSION}) installed successfully to ${INSTALL_PREFIX}"
echo -e "\n  Run: ${BOLD}source ~/.bashrc${RESET}  (or open a new terminal)"
echo -e "  Then verify with: ${BOLD}g++ --version${RESET}\n"
