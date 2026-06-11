#!/usr/bin/env bash
set -euo pipefail

GHCUP_VERSION="0.1.30.0"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    GHCUP_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    GHCUP_ARCH="aarch64"
else
    echo "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

URL="https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/${GHCUP_ARCH}-linux-ghcup"
INSTALL_DIR="${HOME}/.polyinstall/haskell"
BIN_DIR="${INSTALL_DIR}/bin"

echo "[+] Target: Haskell Toolchain via GHCup (${GHCUP_ARCH})"
mkdir -p "$BIN_DIR"

echo "[+] Downloading official GHCup core engine binary..."
curl -sSL -o "${BIN_DIR}/ghcup" "$URL"
chmod +x "${BIN_DIR}/ghcup"

export PATH="${BIN_DIR}:${PATH}"

echo "[+] Non-interactively bootstrapping stable GHC compiler..."
ghcup --no-channel install ghc recommended

echo "[+] Non-interactively bootstrapping Cabal build system..."
ghcup --no-channel install cabal recommended

echo "[+] Injecting path system profiles..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "GHCUP_BIN" "$SHELL_RC"; then
    echo -e "\n# PolyInstall Haskell Configuration" >> "$SHELL_RC"
    echo "export PATH=\"\${HOME}/.ghcup/bin:\${HOME}/.cabal/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Haskell engineering toolchain configured successfully!"
echo "[*] Run 'source $SHELL_RC' to begin using ghc/cabal."
