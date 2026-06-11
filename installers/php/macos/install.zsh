#!/usr/bin/env zsh
set -euo pipefail

PHP_VERSION="8.3.11"
URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"
INSTALL_DIR="${HOME}/.polyinstall/php"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: PHP v${PHP_VERSION} for macOS"
if ! command -v cc &> /dev/null; then
    print "[-] Apple Command Line Tools not detected. Running trigger..." >&2
    xcode-select --install
    exit 1
fi

print "[+] Downloading payload source..."
curl -sSL -o "${TEMP_DIR}/php.tar.gz" "$URL"

print "[+] Unpacking source metadata..."
mkdir -p "${TEMP_DIR}/source"
tar -xzf "${TEMP_DIR}/php.tar.gz" -C "${TEMP_DIR}/source" --strip-components=1

cd "${TEMP_DIR}/source"
print "[+] Generating local cross-compilation configurations..."
./configure --prefix="${INSTALL_DIR}" --disable-all --enable-cli

print "[+] Building application engine..."
CORES=$(sysctl -n hw.logicalcpu || echo 2)
make -j"${CORES}"
make install

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_PHP" "$ZSHRC"; then
    print "\n# POLYINSTALL_PHP" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] PHP successfully built from source natively!"
print "[*] Run: source ~/.zshrc"
