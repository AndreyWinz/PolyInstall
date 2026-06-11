#!/usr/bin/env zsh
set -euo pipefail

DOTNET_VERSION="8.0.401"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOTNET_ARCH="x64"
elif [ "$ARCH" = "arm64" ]; then
    DOTNET_ARCH="arm64"
else
    print "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="dotnet-sdk-${DOTNET_VERSION}-osx-${DOTNET_ARCH}.tar.gz"
URL="https://dotnetcli.azureedge.net/dotnet/Sdk/${DOTNET_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/dotnet"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: .NET SDK v${DOTNET_VERSION} for macOS (${DOTNET_ARCH})"
print "[+] Downloading payload binaries..."
curl -sSL -o "${TEMP_DIR}/dotnet.tar.gz" "$URL"

print "[+] Purging target directory & Extracting payload..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar -xzf "${TEMP_DIR}/dotnet.tar.gz" -C "$INSTALL_DIR"

ZSHRC="${HOME}/.zshrc"
if ! grep -q "DOTNET_ROOT" "$ZSHRC"; then
    print "\n# PolyInstall .NET Engine" >> "$ZSHRC"
    print "export DOTNET_ROOT=\"${INSTALL_DIR}\"" >> "$ZSHRC"
    print "export PATH=\"\$DOTNET_ROOT:\$PATH\"" >> "$ZSHRC"
fi

print "[+] .NET Runtime Core successfully assigned!"
print "[*] Run: source ~/.zshrc"
