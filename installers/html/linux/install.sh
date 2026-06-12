#!/usr/bin/env bash
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

echo "[+] Target: W3C HTML5 Validation Suite & Local HTTP Server"
mkdir -p "${INSTALL_DIR}/bin"

echo "[+] Fetching W3C Validator JAR asset archive..."
curl -sSL -o "${TEMP_DIR}/vnu.zip" "$URL"
unzip -q "${TEMP_DIR}/vnu.zip" -d "$TEMP_DIR"
cp "${TEMP_DIR}/dist/vnu.jar" "${INSTALL_DIR}/vnu.jar"

echo "[+] Generating native shell runner alias wrapper..."
cat << 'EOF' > "${INSTALL_DIR}/bin/html-validate"
#!/usr/bin/env bash
export JAVA_HOME="${HOME}/.polyinstall/java"
export PATH="${JAVA_HOME}/bin:${PATH}"
java -jar "${HOME}/.polyinstall/html/vnu.jar" "$@"
EOF
chmod +x "${INSTALL_DIR}/bin/html-validate"

echo "[+] Fetching local static HTTP dev server module via npm..."
npm config set prefix "$INSTALL_DIR"
npm install -g http-server

echo "[+] Exporting environmental system profiles..."
SHELL_RC="${HOME}/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "POLYINSTALL_HTML" "$SHELL_RC"; then
    echo -e "\n# POLYINSTALL_HTML" >> "$SHELL_RC"
    echo "export PATH=\"${INSTALL_DIR}/bin:\${PATH}\"" >> "$SHELL_RC"
fi

echo "[+] HTML5 toolchain configuration pipeline completed!"
echo "[*] Run 'source $SHELL_RC' to initialize tools."
