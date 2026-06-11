#!/usr/bin/env zsh
set -euo pipefail

R_VERSION="4.4.2"
URL="https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz"
INSTALL_DIR="${HOME}/.polyinstall/r"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: R Engine v${R_VERSION} for macOS"
if ! command -v cc &> /dev/null; then
    print "[-] Apple Command Line Tools not detected. Triggering prompt..." >&2
    xcode-select --install
    exit 1
fi

print "[+] Downloading R source payload..."
curl -sSL -o "${TEMP_DIR}/R.tar.gz" "$URL"

print "[+] Unpacking source contents..."
mkdir -p "${TEMP_DIR}/source"
tar -xzf "${TEMP_DIR}/R.tar.gz" -C "${TEMP_DIR}/source" --strip-components=1

cd "${TEMP_DIR}/source"
print "[+] Running source tree system configurations..."
./configure --prefix="${INSTALL_DIR}" --with-x=no --with-recommended-packages=no

print "[+] Compiling application engine artifacts..."
CORES=$(sysctl -n hw.logicalcpu || echo 2)
make -j"${CORES}"
make install

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_R" "$ZSHRC"; then
    print "\n# POLYINSTALL_R" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Standalone R build sequence complete!"
print "[*] Run: source ~/.zshrc"
