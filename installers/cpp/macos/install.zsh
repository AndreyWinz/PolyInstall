#!/usr/bin/env zsh
# =============================================================================
# PolyInstall — C++ Installer (macOS, Zsh)
# =============================================================================
# On macOS, Apple Clang (installed via Xcode Command Line Tools) supports
# both C and C++ out of the box. The `clang++` driver is provided alongside
# `clang` as part of the same CLT package — no separate C++ install is needed.
#
# This installer:
#   1. Checks whether CLT (and thus `clang++`) is already installed.
#   2. If not, triggers the system xcode-select prompt and waits for it.
#   3. Verifies `clang++` specifically (not just `clang`) and prints info.
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

# ── Check if CLT + clang++ is already installed ───────────────────────────────
log "Checking for Xcode Command Line Tools (clang++)..."

if xcode-select -p &>/dev/null && command -v clang++ &>/dev/null; then
    CLT_PATH="$(xcode-select -p)"
    CLANGPP_VERSION="$(clang++ --version | head -1)"
    success "Xcode Command Line Tools are already installed."
    success "Path:     ${CLT_PATH}"
    success "clang++:  ${CLANGPP_VERSION}"
    print ""
    print "  Verify C++ compilation with:"
    print "  ${BOLD}printf '#include<iostream>\\nint main(){std::cout<<\"hello\\\\n\";}\\n' | clang++ -x c++ - -o /tmp/hi && /tmp/hi${RESET}"
    print ""
    exit 0
fi

# ── Trigger CLT installation ──────────────────────────────────────────────────
log "Xcode Command Line Tools not found. Triggering installation prompt..."
print ""
warn "A system dialog will appear — click 'Install' (not 'Get Xcode')."
warn "This installer will poll every 15 seconds and continue automatically."
print ""

xcode-select --install 2>/dev/null || true

# ── Wait for completion ───────────────────────────────────────────────────────
log "Waiting for Xcode Command Line Tools installation to complete..."

TIMEOUT=1800
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

sleep 5

# ── Verify clang++ specifically ───────────────────────────────────────────────
if ! command -v clang++ &>/dev/null; then
    error "Installation complete but 'clang++' is not available. Try opening a new terminal."
fi

CLT_PATH="$(xcode-select -p)"
CLANGPP_VERSION="$(clang++ --version | head -1)"

success "Xcode Command Line Tools installed successfully."
success "Path:     ${CLT_PATH}"
success "clang++:  ${CLANGPP_VERSION}"
print ""
print "  Verify C++ compilation with:"
print "  ${BOLD}printf '#include<iostream>\\nint main(){std::cout<<\"hello\\\\n\";}\\n' | clang++ -x c++ - -o /tmp/hi && /tmp/hi${RESET}"
print ""
