import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

console.log("[+] Initializing Cross-Language TypeScript Installer Layer for HTML5...");

const VNU_VERSION = "20.6.30";
const url = `https://github.com/validator/validator/releases/download/${VNU_VERSION}/vnu-${VNU_VERSION}.jar.zip`;

const homeDir = os.homedir();
const installDir = path.join(homeDir, '.polyinstall', 'html');
const binDir = path.join(installDir, 'bin');
const tempDir = path.join(os.tmpdir(), 'PolyInstallHtml');

const nodeBinDir = os.platform() === 'win32'
    ? path.join(homeDir, '.polyinstall', 'node')
    : path.join(homeDir, '.polyinstall', 'node', 'bin');

process.env.PATH = nodeBinDir + path.delimiter + process.env.PATH;

if (!fs.existsSync(binDir)) {
    fs.mkdirSync(binDir, { recursive: true });
}
if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
}

console.log("[+] Transporting W3C deployment packages from remote stream mirrors...");
const zipDest = path.join(tempDir, 'vnu.zip');

if (os.platform() === 'win32') {
    execSync(`powershell -Command "Invoke-WebRequest -Uri '${url}' -OutFile '${zipDest}' -UseBasicParsing"`);
    execSync(`powershell -Command "Expand-Archive -Path '${zipDest}' -DestinationPath '${tempDir}\\Unpacked' -Force"`);
    fs.copyFileSync(path.join(tempDir, 'Unpacked', 'dist', 'vnu.jar'), path.join(installDir, 'vnu.jar'));
    
    // Create execution batch file for cmd processing pipelines
    const batchData = `@echo off\nset JAVA_HOME=%USERPROFILE%\\.polyinstall\\java\nset PATH=%JAVA_HOME%\\bin;%PATH%\njava -jar "%USERPROFILE%\\.polyinstall\\html\\vnu.jar" %*\n`;
    fs.writeFileSync(path.join(binDir, 'html-validate.bat'), batchData);
} else {
    execSync(`curl -sSL -o "${zipDest}" "${url}"`);
    execSync(`unzip -q "${zipDest}" -d "${tempDir}"`);
    fs.copyFileSync(path.join(tempDir, 'dist', 'vnu.jar'), path.join(installDir, 'vnu.jar'));

    const javaHomeString = os.platform() === 'darwin' 
        ? `\nexport JAVA_HOME="\${HOME}/.polyinstall/java/Contents/Home"\n[[ ! -d "$JAVA_HOME" ]] && export JAVA_HOME="\${HOME}/.polyinstall/java"`
        : `\nexport JAVA_HOME="\${HOME}/.polyinstall/java"`;

    const shellScriptData = `#!/usr/bin/env sh${javaHomeString}\nexport PATH="\${JAVA_HOME}/bin:\${PATH}"\njava -jar "\${HOME}/.polyinstall/html/vnu.jar" "$@"\n`;
    const runnerPath = path.join(binDir, 'html-validate');
    fs.writeFileSync(runnerPath, shellScriptData);
    execSync(`chmod +x "${runnerPath}"`);
}

console.log("[+] Invoking isolated global npm server component downloads...");
execSync(`npm config set prefix "${installDir}"`, { env: process.env, stdio: 'inherit' });
execSync('npm install -g http-server', { env: process.env, stdio: 'inherit' });

console.log("[+] Committing variable mapping changes permanently...");
if (os.platform() === 'win32') {
    execSync(`powershell -Command "$p=[Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*\\\\html\\\\bin*'){[Environment]::SetEnvironmentVariable('PATH', '${binDir};${installDir};' + $p, 'User')}"`);
} else {
    const rcFile = (process.env.SHELL || '').includes('zsh') ? '.zshrc' : '.bashrc';
    const rcPath = path.join(homeDir, rcFile);
    const envBlock = `\n# PolyInstall HTML5 Toolchain\nexport PATH="${binDir}:$PATH"\n`;
    fs.appendFileSync(rcPath, envBlock);
}

console.log("[*] SUCCESS: HTML5 checking tools and dev servers mapped via TypeScript engine.");
