const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

console.log("[+] Initializing Cross-Language JavaScript Installer Layer for TypeScript...");

const homeDir = os.homedir();
const installDir = path.join(homeDir, '.polyinstall', 'typescript');
const nodeBinDir = cfgWindows() 
    ? path.join(homeDir, '.polyinstall', 'node')
    : path.join(homeDir, '.polyinstall', 'node', 'bin');

// Inject our local Node runtime into the environment path array dynamically
process.env.PATH = nodeBinDir + path.delimiter + process.env.PATH;

try {
    // Sanity check for operational presence of npm package tools
    execSync(cfgWindows() ? 'where npm' : 'command -v npm');
} catch (err) {
    console.error("[-] Dependency Fault: Standalone npm tool missing in active path array.");
    console.error("[-] Please deploy the JavaScript node bundle first.");
    process.exit(1);
}

console.log(`[+] Provisioning container destination mapping: ${installDir}`);
if (!fs.existsSync(installDir)) {
    fs.mkdirSync(installDir, { recursive: true });
}

console.log("[+] Configuring npm target prefix pointers to userspace location...");
execSync(`npm config set prefix "${installDir}"`, { env: process.env, stdio: 'inherit' });

console.log("[+] Transmitting package deployment pipeline command hooks...");
execSync('npm install -g typescript', { env: process.env, stdio: 'inherit' });

console.log("[+] Registering permanent system variables...");
if (cfgWindows()) {
    const regCmd = `powershell -Command "$p=[Environment]::GetEnvironmentVariable('PATH','User'); if($p -notlike '*\\\\.polyinstall\\\\typescript*'){[Environment]::SetEnvironmentVariable('PATH', '${installDir};' + $p, 'User')}"`;
    execSync(regCmd);
} else {
    const shellEnv = process.env.SHELL || '';
    const rcName = shellEnv.includes('zsh') ? '.zshrc' : '.bashrc';
    const rcPath = path.join(homeDir, rcName);
    
    const envBlock = `\n# PolyInstall TypeScript Compiler\nexport PATH="${installDir}/bin:$PATH"\n`;
    fs.appendFileSync(rcPath, envBlock);
}

console.log("[*] SUCCESS: TypeScript compilation environment initialized via JavaScript executor.");

function cfgWindows() {
    return os.platform() === 'win32';
}
