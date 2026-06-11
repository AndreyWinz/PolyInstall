#!/usr/bin/env bash
set -euo pipefail

DOTNET_VERSION="8.0.401"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOTNET_ARCH="x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DOTNET_ARCH="arm64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="dotnet-sdk-${DOTNET_VERSION}-linux-${DOTNET_ARCH}.tar.gz"
URL="https://dotnetcli.azureedge.net/dotnet/Sdk/${DOTNET_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/dotnet"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: .NET SDK v${DOTNET_VERSION} (${DOTNET_ARCH})"
echo "[+] Downloading standalone binary archive..."
curl -sSL -o "${TEMP_DIR}/dotnet.tar.gz" "$URL"

echo "[+] Recreating target workspace directory..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo "[+] Extracting .NET binary payloads..."
tar -xzf "${TEMP_DIR}/dotnet.tar.gz" -C "$INSTALL_DIR"

echo "[+] Injecting system profiles..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "DOTNET_ROOT" "$SHELL_RC"; then
    echo -e "\n# PolyInstall .NET C# Configuration" >> "$SHELL_RC"
    echo "export DOTNET_ROOT=\"${INSTALL_DIR}\"" >> "$SHELL_RC"
    echo "export PATH=\"\${DOTNET_ROOT}:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] .NET SDK environment completely installed!"
echo "[*] Run 'source $SHELL_RC' to refresh your current terminal window."
