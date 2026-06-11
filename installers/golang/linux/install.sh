#!/usr/bin/env bash
set -euo pipefail

GO_VERSION="1.26.1" # Target stable 2026 version
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    GO_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    GO_ARCH="arm64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
URL="https://dl.google.com/go/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/go"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: Go v${GO_VERSION} for Linux (${GO_ARCH})"
echo "[+] Fetching checksum..."
# Fetching the official checksum dynamically
SHA256=$(curl -sSL "${URL}.sha256")

echo "[+] Downloading archive..."
curl -sSL -o "${TEMP_DIR}/${TARBALL}" "$URL"

echo "[+] Verifying integrity..."
echo "${SHA256}  ${TEMP_DIR}/${TARBALL}" | sha256sum --check --status

echo "[+] Extracting to ${INSTALL_DIR}..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar -C "$INSTALL_DIR" --strip-components=1 -xzf "${TEMP_DIR}/${TARBALL}"

echo "[+] Configuring environment variables..."
SHELL_RC="${HOME}/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="${HOME}/.zshrc"
fi

# Ensure lines are injected cleanly if not present
if ! grep -q "GOROOT=" "$SHELL_RC"; then
    echo -e "\n# PolyInstall Go Configuration" >> "$SHELL_RC"
    echo "export GOROOT=\"${INSTALL_DIR}\"" >> "$SHELL_RC"
    echo "export PATH=\"\${GOROOT}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Go installation complete!"
echo "[*] Run 'source $SHELL_RC' or restart your terminal to use 'go'."
