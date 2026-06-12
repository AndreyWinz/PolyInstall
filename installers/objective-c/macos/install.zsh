#!/usr/bin/env zsh
set -euo pipefail

INSTALL_DIR="${HOME}/.polyinstall/objc"
mkdir -p "${INSTALL_DIR}/bin"

print "[+] Target: Native macOS Apple Objective-C Toolchain Wrapper"

print "[+] Generating compilation wrapper script matching Clang Cocoa frameworks..."
cat << 'EOF' > "${INSTALL_DIR}/bin/objc-build"
#!/usr/bin/env zsh
if ! command -v clang &> /dev/null; then
    print "[-] Apple Clang toolchain missing. Running xcode-select initialization..." >&2
    xcode-select --install
    exit 1
fi
# Auto-compile targeting native macOS Cocoa foundation layers cleanly
clang -framework Foundation "$@"
EOF
chmod +x "${INSTALL_DIR}/bin/objc-build"

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_OBJC" "$ZSHRC"; then
    print "\n# POLYINSTALL_OBJC" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] Native Objective-C wrapper successfully linked!"
print "[*] Run: source ~/.zshrc"
