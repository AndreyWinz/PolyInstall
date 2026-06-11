#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    RUST_TARGET="x86_64-unknown-linux-gnu"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    RUST_TARGET="aarch64-unknown-linux-gnu"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

URL="https://static.rust-lang.org/rustup/dist/${RUST_TARGET}/rustup-init"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: Rust Environment via rustup-init (${RUST_TARGET})"
echo "[+] Fetching native toolchain initialization package..."
curl -sSL -o "${TEMP_DIR}/rustup-init" "$URL"
chmod +x "${TEMP_DIR}/rustup-init"

echo "[+] Executing headless standalone unattended installation..."
"${TEMP_DIR}/rustup-init" -y --no-modify-path

echo "[+] Injecting local configuration tracking arrays..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "CARGO_HOME" "$SHELL_RC"; then
    echo -e "\n# PolyInstall Rust Toolchain Environment" >> "$SHELL_RC"
    echo "export PATH=\"\${HOME}/.cargo/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Rust systems deployment pipeline completed!"
echo "[*] Run 'source $SHELL_RC' to initialize cargo/rustc context."
