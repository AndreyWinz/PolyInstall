#!/usr/bin/env bash
set -euo pipefail

PHP_VERSION="8.3.11"
URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"
INSTALL_DIR="${HOME}/.polyinstall/php"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: PHP v${PHP_VERSION} (Source Compilation)"
echo "[+] Checking for compiler tools..."
for cmd in gcc make tar curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "[-] Missing dependency requirement: $cmd" >&2
        exit 1
    fi
done

echo "[+] Downloading source archive..."
curl -sSL -o "${TEMP_DIR}/php.tar.gz" "$URL"

echo "[+] Extracting..."
mkdir -p "${TEMP_DIR}/source"
tar -xzf "${TEMP_DIR}/php.tar.gz" -C "${TEMP_DIR}/source" --strip-components=1

cd "${TEMP_DIR}/source"
echo "[+] Configuring minimum lean build..."
./configure --prefix="${INSTALL_DIR}" \
            --disable-all \
            --enable-cli \
            --enable-mbstring \
            --enable-json

echo "[+] Compiling binaries (this may take a few minutes)..."
JOBS=$(nproc 2>/dev/null || echo 2)
make -j"${JOBS}"
make install

echo "[+] Updating environment configuration..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_PHP" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_PHP" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] PHP compilation setup complete!"
echo "[*] Run 'source $SHELL_RC' to initialize."
