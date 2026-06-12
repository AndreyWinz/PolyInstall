#!/usr/bin/env zsh
set -euo pipefail

VNU_VERSION="20.6.30"
URL="https://github.com/validator/validator/releases/download/${VNU_VERSION}/vnu-${VNU_VERSION}.jar.zip"
INSTALL_DIR="${HOME}/.polyinstall/html"
TEMP_DIR=$(mktemp -d)

export PATH="${HOME}/.polyinstall/node/bin:${PATH}"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print "[+] Target: HTML5 Engineering Toolchain Suite for macOS"
mkdir -p "${INSTALL_DIR}/bin"

print "[+] Extracting W3C Validator core asset maps..."
curl -sSL -o "${TEMP_DIR}/vnu.zip" "$URL"
unzip -q "${TEMP_DIR}/vnu.zip" -d "$TEMP_DIR"
cp "${TEMP_DIR}/dist/vnu.jar" "${INSTALL_DIR}/vnu.jar"

print "[+] Writing Zsh runner script abstraction hooks..."
cat << 'EOF' > "${INSTALL_DIR}/bin/html-validate"
#!/usr/bin/env zsh
export JAVA_HOME="${HOME}/.polyinstall/java/Contents/Home"
[[ ! -d "$JAVA_HOME" ]] && export JAVA_HOME="${HOME}/.polyinstall/java"
export PATH="${JAVA_HOME}/bin:${PATH}"
java -jar "${HOME}/.polyinstall/html/vnu.jar" "$@"
EOF
chmod +x "${INSTALL_DIR}/bin/html-validate"

print "[+] Mapping localized development web servers via npm..."
npm config set prefix "$INSTALL_DIR"
npm install -g http-server

ZSHRC="${HOME}/.zshrc"
if ! grep -q "POLYINSTALL_HTML" "$ZSHRC"; then
    print "\n# POLYINSTALL_HTML" >> "$ZSHRC"
    print "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> "$ZSHRC"
fi

print "[+] HTML5 developer ecosystem completely active!"
print "[*] Run: source ~/.zshrc"
