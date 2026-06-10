#!/usr/bin/env zsh
# =============================================================================
# PolyInstall — C Installer (macOS, Zsh)
# =============================================================================
# On macOS, the canonical C compiler is Apple Clang, shipped as part of
# Xcode Command Line Tools. There is no official Apple source tarball to
# download — CLT is distributed as a signed Apple package.
#
# This installer therefore:
#   1. Checks whether CLT (and thus `clang`) is already installed.
#   2. If not, triggers the system xcode-select prompt to install them,
#      then waits for completion.
#   3. Verifies the resulting compiler and prints version info.
#
# If you specifically want GCC on macOS, run the Linux installer variant
# inside a compatible environment, or install GCC via a package manager
# after CLT is set up.
#
# Usage:
#   chmod +x install.zsh
#   ./install.zsh
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
BOLD="\033[1m"
RESET="\033[0m"

log()     { print -P "${CYAN}${BOLD}[polyinstall]${RESET} $*" }
success() { print -P "${GREEN}${BOLD}[ok]${RESET} $*" }
warn()    { print -P "${YELLOW}${BOLD}[warn]${RESET} $*" }
error()   { print -P "${RED}${BOLD}[error]${RESET} $*" >&2; exit 1 }

# ── Check if CLT is already installed ────────────────────────────────────────
log "Checking for Xcode Command Line Tools..."

if xcode-select -p &>/dev/null && command -v clang &>/dev/null; then
    CLT_PATH="$(xcode-select -p)"
    CLANG_VERSION="$(clang --version | head -1)"
    success "Xcode Command Line Tools are already installed."
    success "Path:    ${CLT_PATH}"
    success "Clang:   ${CLANG_VERSION}"
    print ""
    print "  Verify C compilation with: ${BOLD}echo '#include<stdio.h>\nint main(){puts(\"hello\");}' | clang -x c - -o /tmp/hi && /tmp/hi${RESET}"
    print ""
    exit 0
fi

# ── Trigger CLT installation ──────────────────────────────────────────────────
log "Xcode Command Line Tools not found. Triggering installation prompt..."
print ""
warn "A system dialog will appear asking you to install the Command Line Tools."
warn "Click 'Install' (not 'Get Xcode') and wait for it to complete."
warn "This installer will poll every 15 seconds and continue automatically."
print ""

# xcode-select --install returns exit code 1 if already installed, which
# we've already handled above. Here we just trigger it and let it run.
xcode-select --install 2>/dev/null || true

# ── Wait for installation to complete ────────────────────────────────────────
log "Waiting for Xcode Command Line Tools installation to complete..."

TIMEOUT=1800   # 30 minutes maximum wait
ELAPSED=0
INTERVAL=15

while ! xcode-select -p &>/dev/null; do
    if [[ $ELAPSED -ge $TIMEOUT ]]; then
        error "Timed out waiting for Xcode Command Line Tools installation."
    fi
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    log "Still waiting... (${ELAPSED}s elapsed)"
done

# Give the installer a moment to fully finalise
sleep 5

# ── Verify ────────────────────────────────────────────────────────────────────
if ! command -v clang &>/dev/null; then
    error "Installation appeared to complete but 'clang' is not available. Try opening a new terminal."
fi

CLT_PATH="$(xcode-select -p)"
CLANG_VERSION="$(clang --version | head -1)"

success "Xcode Command Line Tools installed successfully."
success "Path:    ${CLT_PATH}"
success "Clang:   ${CLANG_VERSION}"
print ""
print "  Verify C compilation with:"
print "  ${BOLD}printf '#include<stdio.h>\\nint main(){puts(\"hello\");}\\n' | clang -x c - -o /tmp/hi && /tmp/hi${RESET}"
print ""
