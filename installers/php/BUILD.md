# PolyInstall: PHP Runtime Engine Installer Suite

PolyInstall provides a self-contained installation suite for the PHP runtime environment. The installers are designed to create clean, isolated PHP CLI environments without relying on system-wide package managers or external distribution frameworks.

**Target Runtime Version:** PHP v8.3.11

---

# Installation Methods

PolyInstall provides four installation paths:

1. Native Linux shell installer
2. Native macOS shell installer
3. Native Windows PowerShell installer
4. Native C++ installer

All installation methods are designed to:

- Install PHP into a user-local workspace
- Avoid unnecessary global dependencies
- Configure environment variables automatically
- Support modern x86_64 and ARM platforms where applicable
- Minimize administrative privilege requirements

---

# Linux Installation

The Linux installer is implemented as a GNU Bash bootstrap script.

It handles architecture detection, installation configuration, and deployment into the PolyInstall workspace while keeping the PHP runtime isolated from system package managers.

## Run

```bash
chmod +x linux/install.sh
./linux/install.sh
```

---

# macOS Installation

The macOS installer is implemented as a native Zsh script.

It supports both Apple Silicon and Intel-based systems and installs an isolated PHP runtime optimized for the host platform.

## Run

```bash
chmod +x macos/install.zsh
./macos/install.zsh
```

---

# Windows Installation

The Windows installer is implemented as a PowerShell script.

It downloads the official PHP package, extracts it into the user's PolyInstall workspace, configures default runtime settings, and updates environment variables as required.

## Run

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

---

# Native C++ Installer

For environments that prefer a compiled installer over shell scripts, PolyInstall includes a standalone C++ implementation.

The C++ installer performs the same installation workflow while operating as a self-contained executable.

Source files are located in:

```text
cpp/
```

---

# Building the Native Installer

## Linux and macOS

Compile using the provided build definitions:

```bash
cd cpp/
make
./php_installer
```

## Windows (MinGW / GCC)

Compile manually from an active development environment:

```bash
cd cpp
g++ -Wall -Wextra -std=c++17 -O2 -o php_installer.exe main.cpp installer.cpp
.\php_installer.exe
```

---

# Post-Installation

Reload your shell profile to ensure updated environment variables are available in the current session.

## Linux/macOS

```bash
source ~/.bashrc
```

or

```bash
source ~/.zshrc
```

---

# Verification

Verify that PHP is installed and available on your system path:

```bash
php -v
```

Expected output should display the installed PHP version and runtime information.
