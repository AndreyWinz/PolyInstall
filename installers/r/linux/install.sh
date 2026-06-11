#!/usr/bin/env bash
set -euo pipefail

R_VERSION="4.4.2"
URL="https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz"
INSTALL_DIR="${HOME}/.polyinstall/r"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[+] Target: R Statistical Engine v${R_VERSION} (Source Compilation)"
echo "[+] Checking basic build tools..."
for cmd in gcc gfortran make tar curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "[-] Missing critical build tool: $cmd" >&2
        echo "[-] Please ensure GCC and Fortran compilers are present." >&2
        exit 1
    fi
done

echo "[+] Downloading R source code..."
curl -sSL -o "${TEMP_DIR}/R.tar.gz" "$URL"

echo "[+] Extracting source files..."
mkdir -p "${TEMP_DIR}/source"
tar -xzf "${TEMP_DIR}/R.tar.gz" -C "${TEMP_DIR}/source" --strip-components=1

cd "${TEMP_DIR}/source"
echo "[+] Configuring sandboxed, standalone build matrix..."
./configure --prefix="${INSTALL_DIR}" \
            --with-x=no \
            --with-recommended-packages=no \
            --enable-R-shlib

echo "[+] Compiling R runtime binaries (this may take a bit)..."
JOBS=$(nproc 2>/dev/null || echo 2)
make -j"${JOBS}"
make install

echo "[+] Patching user environment profiles..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_R" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_R" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] R environment successfully installed!"
echo "[*] Run 'source $SHELL_RC' to initialize the terminal workspace."
