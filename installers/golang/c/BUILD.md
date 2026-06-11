# PolyInstall: Go (Golang) Installer Suite

PolyInstall provides a fully self-contained, cross-platform installation suite for the Go programming language runtime. Following the PolyInstall philosophy, all installers rely exclusively on native operating system utilities or self-compiled binaries, avoiding external package managers and third-party installation frameworks.

**Target Runtime Version:** Go v1.26.1

---

# Directory Structure

```text
installers/go/
├── linux/
│   └── install.sh      # GNU Bash bootstrap installer
├── macos/
│   └── install.zsh     # Native Zsh bootstrap installer
├── windows/
│   └── install.ps1     # PowerShell bootstrap installer
└── c/
    ├── main.c          # Native installer entry point
    ├── steps.c         # Cross-platform deployment logic
    ├── log.c           # Terminal logging and UI helpers
    ├── installer.h     # Shared declarations and constants
    ├── Makefile        # Linux/macOS build configuration
    └── BUILD.md        # Additional build documentation
```

---

# Installation Methods

PolyInstall provides four installation paths:

1. Native Linux shell installer
2. Native macOS shell installer
3. Native Windows PowerShell installer
4. Native compiled C installer

All methods perform the same core tasks:

- Detect system architecture automatically
- Download the official Go distribution package
- Verify package integrity using published checksums
- Install Go into a user-local PolyInstall directory
- Configure environment variables and executable paths
- Avoid requiring administrator privileges whenever possible

---

# Linux Installation

The Linux installer is implemented as a portable GNU Bash bootstrap script.

It automatically detects whether the system is running `amd64` or `arm64`, downloads the appropriate Go archive, verifies its checksum, extracts it into the PolyInstall workspace, and updates the user's shell profile.

By default, Go is installed to:

```text
~/.polyinstall/go
```

## Run

```bash
chmod +x linux/install.sh
./linux/install.sh
```

---

# macOS Installation

The macOS installer is implemented as a native Zsh script and supports both Apple Silicon and Intel systems.

## Run

```bash
chmod +x macos/install.zsh
./macos/install.zsh
```

---

# Windows Installation

The Windows installer is implemented as a PowerShell script.

## Run

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

---

# Native C Installer

For environments where shell scripting is undesirable, PolyInstall also includes a fully native installer implemented in C.

## Linux and macOS

```bash
cd c/
make
./go_installer
```

## Windows (GCC / MinGW)

```bash
cd c
gcc -Wall -Wextra -O2 -o go_installer.exe main.c steps.c log.c
.\go_installer.exe
```

---

# Verification

```bash
go version
```

Expected output:

```text
go version go1.26.1 <platform>/<architecture>
```
