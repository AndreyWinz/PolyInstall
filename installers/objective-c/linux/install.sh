#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.polyinstall/objc"

echo "[+] Target: GNUstep Objective-C Runtime (Userspace Environment)"
mkdir -p "${INSTALL_DIR}/bin"

echo "[+] Generating standalone Objective-C compilation helper wrapper..."
cat << 'EOF' > "${INSTALL_DIR}/bin/objc-build"
#!/usr/bin/env bash
if ! command -v gcc &> /dev/null; then
    echo "[-] Error: GCC compiler not found on host system." >&2
    exit 1
fi
# Auto-link the GNUstep Object Runtime engine and Foundation tracking loops
gcc -x objective-c "$@" -lobjc -lgnustep-base
EOF
chmod +x "${INSTALL_DIR}/bin/objc-build"

echo "[+] Injecting system login shell profile variables..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_OBJC" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_OBJC" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] Objective-C environment setup complete!"
echo "[*] Run 'source $SHELL_RC' to initialize your workspace toolchain."
