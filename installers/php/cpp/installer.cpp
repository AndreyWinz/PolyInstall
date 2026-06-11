#include "installer.hpp"
#include <iostream>
#include <cstdlib>
#include <stdexcept>

#if defined(_WIN32)
#include <windows.h>
#else
#include <unistd.h>
#endif

PhpInstaller::PhpInstaller(const std::string& ver) : version(ver) {
#if defined(_WIN32)
    const char* userProfile = std::getenv("USERPROFILE");
    installDir = std::string(userProfile) + "\\.polyinstall\\php";
    tempArchive = std::string(std::getenv("TEMP")) + "\\php_payload.zip";
#else
    const char* homeDir = std::getenv("HOME");
    installDir = std::string(homeDir) + "/.polyinstall/php";
    tempArchive = "/tmp/php_payload.tar.gz";
#endif
}

bool PhpInstaller::runCommand(const std::string& cmd) {
    return std::system(cmd.c_str()) == 0;
}

bool PhpInstaller::downloadFile(const std::string& url, const std::string& dest) {
#if defined(_WIN32)
    std::string cmd = "powershell -Command \"Invoke-WebRequest -Uri '" + url + "' -OutFile '" + dest + "' -UseBasicParsing\"";
#else
    std::string cmd = "curl -sSL -o \"" + dest + "\" \"" + url + "\"";
#endif
    return runCommand(cmd);
}

void PhpInstaller::execute() {
    std::cout << "[+] Bootstrapping C++ Object Installer Engine..." << std::endl;

#if defined(_WIN32)
    std::string url = "https://windows.php.net/downloads/releases/php-" + version + "-Win32-vs16-x64.zip";
    std::cout << "[+] Downloading Windows Binary release zip packaging..." << std::endl;
    if (!downloadFile(url, tempArchive)) throw std::runtime_error("Network download pipe error encountered.");

    std::cout << "[+] Cleaning target destination & Unpacking..." << std::endl;
    runCommand("powershell -Command \"if(Test-Path '" + installDir + "'){Remove-Item -Recurse -Force '" + installDir + "'}; Expand-Archive -Path '" + tempArchive + "' -DestinationPath '" + installDir + "' -Force\"");
    runCommand("powershell -Command \"Copy-Item -Path '" + installDir + "\\php.ini-development' -Destination '" + installDir + "\\php.ini'\"");

    std::cout << "[+] Committing registry changes..." << std::endl;
    std::string pathUpdate = "powershell -Command \"$p = [Environment]::GetEnvironmentVariable('PATH', 'User'); if($p -notlike '*" + installDir + "*'){[Environment]::SetEnvironmentVariable('PATH', '" + installDir + ";' + $p, 'User')}\"";
    runCommand(pathUpdate);
#else
    std::string url = "https://www.php.net/distributions/php-" + version + ".tar.gz";
    std::cout << "[+] Pulling engine code mirror tarball from: " << url << std::endl;
    if (!downloadFile(url, tempArchive)) throw std::runtime_error("Source file transfer failed.");

    std::cout << "[+] Extracting source and preparing configuration matrices..." << std::endl;
    runCommand("rm -rf /tmp/php_src && mkdir -p /tmp/php_src && tar -xzf " + tempArchive + " -C /tmp/php_src --strip-components=1");
    
    std::cout << "[+] Compiling source (make infrastructure pipelines)..." << std::endl;
    std::string buildCmd = "cd /tmp/php_src && ./configure --prefix=\"" + installDir + "\" --disable-all --enable-cli && make -j2 && make install";
    if (!runCommand(buildCmd)) throw std::runtime_error("Compilation system error. Verify development tool setups.");

    std::cout << "[+] Appending local login user environment profiles..." << std::endl;
    std::string rcFile = std::string(std::getenv("HOME")) + "/.bashrc";
    char* shellEnv = std::getenv("SHELL");
    if (shellEnv && std::string(shellEnv).find("zsh") != std::string::npos) {
        rcFile = std::string(std::getenv("HOME")) + "/.zshrc";
    }
    runCommand("echo '\nexport PATH=\"" + installDir + "/bin:$PATH\"' >> " + rcFile);
#endif

    std::cout << "[*] PHP Instance Lifecycle completely deployed via C++ program mapping." << std::endl;
}