#!/usr/bin/env zsh
set -euo pipefail

GHCUP_VERSION="0.1.30.0"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    GHCUP_ARCH="x86_64"
elif [ "$ARCH" = "arm64" ]; then
    GHCUP_ARCH="aarch64"
else
    print "[-] Unsupported architecture: $ARCH" >&2
    exit 1
fi

URL="https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/${GHCUP_ARCH}-apple-darwin-ghcup"
INSTALL_DIR="${HOME}/.polyinstall/haskell"
BIN_DIR="${INSTALL_DIR}/bin"

print "[+] Target: Haskell GHCup Toolchain for macOS (${ARCH})"
mkdir -p "$BIN_DIR"

print "[+] Downloading standard standalone GHCup binary..."
curl -sSL -o "${BIN_DIR}/ghcup" "$URL"
chmod +x "${BIN_DIR}/ghcup"

export PATH="${BIN_DIR}:${PATH}"

print "[+] Deploying recommended native GHC compiler assembly..."
ghcup --no-channel install ghc recommended

print "[+] Deploying Cabal build driver engine..."
ghcup --no-channel install cabal recommended

ZSHRC="${HOME}/.zshrc"
if ! grep -q "GHCUP_BIN" "$ZSHRC"; then
    print "\n# PolyInstall Haskell Environment" >> "$ZSHRC"
    print "export PATH=\"\${HOME}/.ghcup/bin:\${HOME}/.cabal/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Haskell configuration arrays committed successfully!"
print "[*] Run: source ~/.zshrc"
