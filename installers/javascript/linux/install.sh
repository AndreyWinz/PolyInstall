#!/usr/bin/env bash
set -euo pipefail

NODE_VERSION="22.11.0"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    NODE_ARCH="x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
URL="https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/node"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: Node.js/JavaScript Runtime v${NODE_VERSION} (${NODE_ARCH})"
echo "[+] Downloading pre-compiled production binary tarball..."
curl -sSL -o "${TEMP_DIR}/node.tar.xz" "$URL"

echo "[+] Purging old directory trees and allocating target path..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo "[+] Extracting Node.js engine layers..."
tar -xJf "${TEMP_DIR}/node.tar.xz" -C "$INSTALL_DIR" --strip-components=1

echo "[+] Exporting environmental system paths..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_NODE" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_NODE" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Node.js/JavaScript environment completely deployed!"
echo "[*] Run 'source $SHELL_RC' to initialize your active shell."
