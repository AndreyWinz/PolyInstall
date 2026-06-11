#!/usr/bin/env zsh
set -euo pipefail

GO_VERSION="1.26.1"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    GO_ARCH="amd64"
elif [ "$ARCH" = "arm64" ]; then
    GO_ARCH="arm64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="go${GO_VERSION}.darwin-${GO_ARCH}.tar.gz"
URL="https://dl.google.com/go/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/go"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: Go v${GO_VERSION} for macOS (${GO_ARCH})"
print "[+] Downloading..."
curl -sSL -o "${TEMP_DIR}/${TARBALL}" "$URL"

print "[+] Verifying checksum..."
EXPECTED_SHA=$(curl -sSL "${URL}.sha256")
ACTUAL_SHA=$(shasum -a 256 "${TEMP_DIR}/${TARBALL}" | awk '{print $1}')

if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
    print "[-] Cryptographic verification failed!" >&2
    exit 1
fi

print "[+] Extracting files..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar -C "$INSTALL_DIR" --strip-components=1 -xzf "${TEMP_DIR}/${TARBALL}"

ZSHRC="${HOME}/.zshrc"
if ! grep -q "GOROOT=" "$ZSHRC"; then
    print "\n# PolyInstall Go Setup" >> "$ZSHRC"
    print "export GOROOT=\"${INSTALL_DIR}\"" >> "$ZSHRC"
    print "export PATH=\"\$GOROOT/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Go setup complete for macOS!"
print "[*] Reload with: source ~/.zshrc"
