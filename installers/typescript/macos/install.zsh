#!/usr/bin/env zsh
set -euo pipefail

INSTALL_DIR="${HOME}/.polyinstall/typescript"
export PATH="${HOME}/.polyinstall/node/bin:${PATH}"

print "[+] Target: TypeScript Platform for macOS"
if ! command -v npm &> /dev/null; then
    print "[-] Local isolated npm registry engine not found." >&2
    print "[-] Ensure the JavaScript subsystem has been deployed first." >&2
    exit 1
fi

print "[+] Allocating clean configuration workspace..."
mkdir -p "$INSTALL_DIR"

print "[+] Re-mapping npm global prefix variables..."
npm config set prefix "$INSTALL_DIR"

print "[+] Pulling package from repository layers..."
npm install -g typescript

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_TYPESCRIPT" "$ZSHRC"; then
    print "\n# POLYINSTALL_TYPESCRIPT" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] TypeScript toolchain environment fully wired!"
print "[*] Run: source ~/.zshrc"
