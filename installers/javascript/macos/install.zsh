#!/usr/bin/env zsh
set -euo pipefail

NODE_VERSION="22.11.0"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    NODE_ARCH="x64"
elif [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
else
    print "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="node-v${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
URL="https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/node"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: Node.js Runtime v${NODE_VERSION} for macOS (${NODE_ARCH})"
print "[+] Downloading standard standalone binary package..."
curl -sSL -o "${TEMP_DIR}/node.tar.gz" "$URL"

print "[+] Freeing deployment space and extracting binary payload..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar -xzf "${TEMP_DIR}/node.tar.gz" -C "$INSTALL_DIR" --strip-components=1

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_NODE" "$ZSHRC"; then
    print "\n# POLYINSTALL_NODE" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] JavaScript ecosystem paths linked successfully!"
print "[*] Run: source ~/.zshrc"
