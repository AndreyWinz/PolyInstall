#!/usr/bin/env zsh
set -euo pipefail

JDK_VERSION="21.0.2+13"
URL_VERSION="jdk-21.0.2%2B13"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    JAVA_ARCH="x64"
elif [ "$ARCH" = "arm64" ]; then
    JAVA_ARCH="aarch64"
else
    print "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

TARBALL="OpenJDK21U-jdk_${JAVA_ARCH}_mac_hotspot_21.0.2_13.tar.gz"
URL="https://github.com/adoptium/temurin21-binaries/releases/download/${URL_VERSION}/${TARBALL}"
INSTALL_DIR="${HOME}/.polyinstall/java"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: Eclipse Temurin JDK v${JDK_VERSION} for macOS (${JAVA_ARCH})"
print "[+] Downloading standalone architecture payload..."
curl -sSL -o "${TEMP_DIR}/java.tar.gz" "$URL"

print "[+] Purging old runtimes and extracting payload..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
# macOS tarballs contain a nested 'Contents/Home' hierarchy directory structure
tar -xzf "${TEMP_DIR}/java.tar.gz" -C "$INSTALL_DIR" --strip-components=1

# Point directly inside the standard macOS Home folder layout if present
FINAL_HOME="$INSTALL_DIR"
[[ -d "${INSTALL_DIR}/Contents/Home" ]] && FINAL_HOME="${INSTALL_DIR}/Contents/Home"

ZSHRC="${HOME}/.zshrc"
if ! grep -q "JAVA_HOME" "$ZSHRC"; then
    print "\n# PolyInstall Java Engine" >> "$ZSHRC"
    print "export JAVA_HOME=\"${FINAL_HOME}\"" >> "$ZSHRC"
    print "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Java toolchain setup completed successfully!"
print "[*] Run: source ~/.zshrc"
