# PolyInstall: .NET Core C# Component SDK Suite

This deployment profile initialises a completely independent workspace implementation setup for the C# language execution layer by mounting the official standalone cross-platform .NET Core Software Development Kit (SDK).

Target Framework Version: .NET SDK v8.0.401

---

## 1. Native Script Bootstrap Frameworks

### Linux Platforms (Bash Script Pipeline)
The engine evaluates local execution architectures, pulls matching packages down directly from Microsoft CDN servers, unpacks binaries securely, and creates matching standard shell terminal aliases profiles.

```bash
chmod +x linux/install.sh
./linux/install.sh
```

## macOS Environments (Zsh Bootstrap Script)

Directly deploys isolated development engines mapped for either M-series ARM runtime structures or standard Intel chips natively inside userspace folders.

```zsh
chmod +x macos/install.zsh
./macos/install.zsh
```

## Windows Shell Integrations (PowerShell Core)

Downloads targeting production zip payloads, extracts components to user profiles, handles custom environment registry mutations, and establishes localized tracking variables dynamically.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

## 2. Custom Native Go Installation Medium

The go/ folder structure houses an alternate installer implementation pipeline written in Go. It can be compiled and launched using the Go execution framework established earlier within the PolyInstall toolkit pipeline.
#### Compilation Protocol
#### On All Operating Systems

If an existing native Go binary tool suite is already configured inside your active system terminal paths, run the compiler engine driver directly from source:
Bash

```bash
cd go/
go build -o dotnet_installer install.go
./dotnet_installer
```

## Path Synchronisation Verification

To initialise path environments directly into your active workspace terminal without executing a physical shell reboot step, run your local profile configurations, source sync definitions:
```bash
# Unix environments
source ~/.bashrc # or source ~/.zshrc

# Toolchain validation execution check
dotnet --version
dotnet new console -o PolyTest
```
