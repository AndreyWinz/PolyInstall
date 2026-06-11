#!/usr/bin/env zsh
set -euo pipefail

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    RUST_TARGET="x86_64-apple-darwin"
elif [ "$ARCH" = "arm64" ]; then
    RUST_TARGET="aarch64-apple-darwin"
else
    print "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

URL="https://static.rust-lang.org/rustup/dist/${RUST_TARGET}/rustup-init"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: Rust Toolkit for macOS (${RUST_TARGET})"
print "[+] Downloading standard bootstrapper component..."
curl -sSL -o "${TEMP_DIR}/rustup-init" "$URL"
chmod +x "${TEMP_DIR}/rustup-init"

print "[+] Driving dynamic backend non-interactive installation..."
"${TEMP_DIR}/rustup-init" -y --no-modify-path

ZSHRC="${HOME}/.zshrc"
if ! grep -q "CARGO_HOME" "$ZSHRC"; then
    print "\n# PolyInstall Cargo Workspace" >> "$ZSHRC"
    print "export PATH=\"\${HOME}/.cargo/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Rust platform lifecycle successfully configured!"
print "[*] Run: source ~/.zshrc"
