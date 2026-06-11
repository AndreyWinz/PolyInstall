#!/usr/bin/env bash
set -euo pipefail

JDK_VERSION="21.0.2+13"
# URL encode the '+' for the download API path
URL_VERSION="jdk-21.0.2%2B13"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    JAVA_ARCH="x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    JAVA_ARCH="aarch64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="OpenJDK21U-jdk_${JAVA_ARCH}_linux_hotspot_21.0.2_13.tar.gz"
URL="https://github.com/adoptium/temurin21-binaries/releases/download/${URL_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/java"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: Eclipse Temurin JDK v${JDK_VERSION} (${JAVA_ARCH})"
echo "[+] Downloading production OpenJDK binary archive..."
curl -sSL -o "${TEMP_DIR}/java.tar.gz" "$URL"

echo "[+] Preparing destination tree..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo "[+] Extracting Java Development Kit runtime..."
tar -xzf "${TEMP_DIR}/java.tar.gz" -C "$INSTALL_DIR" --strip-components=1

echo "[+] Injecting system profile variables..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "JAVA_HOME" "$SHELL_RC"; then
    echo -e "\n# PolyInstall Java JDK Configuration" >> "$SHELL_RC"
    echo "export JAVA_HOME=\"${INSTALL_DIR}\"" >> "$SHELL_RC"
    echo "export PATH=\"\${JAVA_HOME}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Java OpenJDK environment completely installed!"
echo "[*] Run 'source $SHELL_RC' to refresh your current terminal context."
