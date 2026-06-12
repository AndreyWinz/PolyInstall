# PolyInstall: Objective-C Development & GNUstep Core Compiler Suite

This installation block provides zero-privilege, clean environment controls to deploy the tools needed to build and run Objective-C code across Linux, macOS, and Windows.

Target Toolchain Base: Standalone GNUstep Compilation Layer Tools

---

## 1. Native Script Bootstrap Frameworks

### Linux Framework Platforms (GNU Bash Driver Script)
Deploys localized compilation shortcut scripts (`objc-build`) directly into userspace directories, dynamically mapping compilation targets for system runtimes.

```bash
chmod +x linux/install.sh
./linux/install.sh
```

### macOS Operating Environments (Zsh Structural Script)

Wraps native hardware Clang handles into a local helper executor script, binding the foundational framework scopes automatically without modifying root paths.

```bash
chmod +x macos/install.zsh
./macos/install.zsh
```

### Windows Administrative Systems (PowerShell Core Matrix)

Downloads a minimal, pre-built binary package of the open-source GNUstep compilation framework, extracts it safely inside home workspaces, and registers system paths.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

## 2. Cross-Language Native C Execution Module

The c/ directory delivers a lightweight installer engine written entirely in pure ANSI C. It can be compiled by any system C compiler on your machine.
Compilation Protocol

Compile and drive the custom execution engine cleanly from your active shell:

```bash
cd c/
gcc install.c -o objc_installer
./objc_installer
```

### Environment Verification Steps

To load your new configurations directly into your active terminal window immediately without restarting your terminal, refresh your environment paths manually:

```bash
# Unix environments synchronization step
source ~/.bashrc # or source ~/.zshrc

# Create a test file (main.m) and compile it using your new tool
# objc-build main.m -o ObjectiveTest
```
