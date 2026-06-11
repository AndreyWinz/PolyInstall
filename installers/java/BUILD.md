# PolyInstall: Java OpenJDK Development Toolchain Suite

This directory supplies clean script and native runtime binary modules to deploy the standalone, high-performance Eclipse Temurin OpenJDK suite into user sandbox environments without root intervention.

Target Base Profile: Eclipse Temurin JDK v21.0.2+13 (LTS)

---

## 1. Native Script Bootstrap Engines

### Linux Terminal Ecosystems (Bash Shell Logic)
Evaluates local compilation architecture profiles, streams verified pre-compiled system tarballs directly from Adoptium release nodes, unpacks contents, and writes system aliases.

```bash
chmod +x linux/install.sh
./linux/install.sh
```
### macOS Operating Environments (Zsh Bootstrap System)

Automatically maps architecture fields to handle Apple Silicon chips or Intel builds, stripping containment subdirectories cleanly and embedding the explicit JAVA_HOME pathway inside shell profiles.

```bash
chmod +x macos/install.zsh
./macos/install.zsh
```

### Windows Administrative Systems (PowerShell Engine)

Fetches long-term stable standalone development zip packages, executes nested item shifting, registers permanent User Environment profiles, and assigns execution properties.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\windows\install.ps1
```

## 2. Cross-Language Native Rust Binary Execution Module

The rust/ path space provisions a lightweight, system-level installer orchestration tool written from scratch in Rust. It compiles down to a completely standalone system executable binary using the Cargo tool suite created in the previous step.
#### Compilation Protocol
#### For All Development Environments

If an operational mapping of the Rust system compiler tool suite is present inside your active shell configuration environment paths, compile the binary natively:

```bash
cd rust/
cargo build --release
./target/release/java_installer
```

### Path Synchronisation Check

To append binary runtimes securely into active terminal interfaces immediately without running a complete system logout cycle, load updates manually via shell tools:

```bash
# Unix terminals update sync
source ~/.bashrc # or source ~/.zshrc

# Run system verification tasks
java -version
javac -version
```
