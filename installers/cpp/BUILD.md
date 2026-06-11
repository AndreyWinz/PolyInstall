# Building the C++ Installer (Python variant)

This installer is written in Python 3 and is **cross-platform** — the same
script handles Linux, macOS, and Windows by detecting the host OS at runtime.

---

## Prerequisites

Python 3.10 or later is required (uses `str | None` union type hints).

No third-party packages are needed. All functionality uses the Python
standard library only (`urllib`, `hashlib`, `tarfile`, `zipfile`,
`subprocess`, `winreg` on Windows, etc.).

---

## Run

```bash
python3 main.py
```

With options:

```bash
python3 main.py --version 14.2.0 --prefix ~/.local/gcc-cpp   # Linux
python3 main.py --version 18.1.8 --prefix ~/.local/llvm      # Windows
python3 main.py                                               # macOS
```

| Flag | Default (Linux) | Default (Windows) | macOS |
|------|----------------|-------------------|-------|
| `--version` | `14.2.0` (GCC) | `18.1.8` (LLVM) | ignored |
| `--prefix` | `~/.local/gcc-cpp` | `%USERPROFILE%\.local\llvm` | ignored |

---

## What it does, per platform

### Linux
1. Checks for `tar`, `make`, and an existing C compiler (needed to bootstrap GCC)
2. Downloads the GCC source tarball from `ftp.gnu.org`
3. Downloads and verifies the accompanying `sha512.sum` file
4. Extracts the tarball and runs `./contrib/download_prerequisites` to fetch GMP, MPFR, and MPC
5. Runs `./configure --enable-languages=c,c++ --disable-multilib`, `make`, and `make install`
6. Appends `<prefix>/bin` to PATH in `~/.bashrc`, `~/.zshrc`, `~/.zprofile` as appropriate

The key difference from the C installer on Linux is `--enable-languages=c,c++`, which produces
both `gcc` and `g++` in the same build.

### macOS
1. Checks whether Xcode Command Line Tools are already installed — specifically verifying `clang++`, not just `clang`
2. If not, triggers `xcode-select --install` and polls every 15 seconds until complete
3. Verifies the resulting `clang++` binary and prints version info

### Windows
1. Downloads the official LLVM pre-built zip for Windows x64 from the LLVM GitHub releases
2. Downloads and verifies the accompanying `.sha256` checksum file
3. Extracts to the install prefix, flattening any nested top-level directory
4. Explicitly verifies both `clang.exe` and `clang++.exe` are present
5. Adds `<prefix>\bin` to the current user's PATH via the Windows registry

---

## File structure

| File | Purpose |
|------|---------|
| `main.py` | Entry point; parses arguments and dispatches to the right platform module |
| `log.py` | Coloured logging helpers (`log`, `ok`, `warn`, `error`) |
| `utils.py` | Shared utilities: download, checksum verification, extraction, PATH update |
| `steps_linux.py` | Linux-specific steps (GCC with C + C++ from source) |
| `steps_macos.py` | macOS-specific steps (Xcode CLT, verifies clang++ specifically) |
| `steps_windows.py` | Windows-specific steps (LLVM/Clang zip, verifies clang++.exe) |
