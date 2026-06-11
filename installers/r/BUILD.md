# PolyInstall: R Computational Statistical Toolchain Suite

This directory contains standalone user-space installers for deploying the R statistical runtime environments natively without relying on root administration escalation pathways or third-party container management abstractions.

Target Environment Base: R Runtime v4.4.2

---

## 1. Native Script Bootstrap Engines

### Linux Terminals (GNU Bash Framework)
Evaluates host compilation components, pulls verified core tarball source matrices directly from active CRAN archives, configures localized isolation parameters, and initiates structural compilation blocks.

```bash
chmod +x linux/install.sh
./linux/install.sh
```

### macOS Operating Profiles (Zsh Bootstrap Script)

Compiles standalone binaries tailored directly to personal target directory configurations, preserving standard isolated tracking environments without accessing root filesystems.

```bash
chmod +x macos/install.zsh
./macos/install.zsh
```

### Windows Administrative Framework (PowerShell Layer)

Pulls distribution executable configurations, runs silent automated unpacking sequences using target directory modifiers directly inside home folders, and alters individual environment variables safely.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

## 2. Cross-Language Native Java Application Engine

The java/ folder houses an implementation mapping written entirely in Java bytecode patterns. It can be compiled and triggered using the OpenJDK developer platform infrastructure initialized during the previous phase of PolyInstall.
Compilation Protocol
On All Operating Systems

If an active instance of the Java compiler (javac) and archiving utility (jar) are accessible inside your terminal paths, build the standalone medium runner manually:

```bash
cd java/
javac RInstaller.java
jar cfm RInstaller.jar manifest.txt RInstaller.class
java -jar RInstaller.jar
```

### Path Workspace Synchronisation

To activate path mutations inside your active shell terminal context maps without running a hard terminal instance reboot loop cycle, execute configurations sync routines:

```bash
# Unix environments synchronisation step
source ~/.bashrc # or source ~/.zshrc

# Toolchain validation check
R --version
```
