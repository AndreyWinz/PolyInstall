#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.polyinstall/typescript"
export PATH="${HOME}/.polyinstall/node/bin:${PATH}"

echo "[+] Target: TypeScript Compiler (tsc) via Userspace npm"
if ! command -v npm &> /dev/null; then
    echo "[-] Node.js/npm not detected in your PolyInstall path context." >&2
    echo "[-] Please run the JavaScript installer suite first." >&2
    exit 1
fi

echo "[+] Creating isolated userspace global directory..."
mkdir -p "$INSTALL_DIR"

echo "[+] Rewiring npm configurations to sandboxed prefix..."
npm config set prefix "$INSTALL_DIR"

echo "[+] Installing official TypeScript package distribution..."
npm install -g typescript

echo "[+] Syncing environment login shell variables..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_TYPESCRIPT" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_TYPESCRIPT" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] TypeScript compiler deployment workflow complete!"
echo "[*] Run 'source $SHELL_RC' to initialize tsc handles."
