# Building the Python Installer (C variant)

This installer is written in C and targets **Linux and macOS**.
For Windows, use `../windows/install.ps1` instead.

---

## Prerequisites

| Tool | Linux | macOS |
|------|-------|-------|
| C compiler (gcc or clang) | `sudo apt install build-essential` | `xcode-select --install` |
| make | included with build-essential | included with Xcode CLT |
| curl | `sudo apt install curl` | pre-installed |

You will also need the standard Python build dependencies for the `./configure` step inside CPython:

```bash
# Debian / Ubuntu
sudo apt install libssl-dev zlib1g-dev libffi-dev \
                 libreadline-dev libbz2-dev libsqlite3-dev

# Fedora / RHEL
sudo dnf install openssl-devel zlib-devel libffi-devel \
                 readline-devel bzip2-devel sqlite-devel
```

On macOS these are provided by Xcode Command Line Tools and Homebrew's OpenSSL if needed.

---

## Build

```bash
cd installers/python/c
make
```

This produces a single binary: `polyinstall_python`.

To use a different compiler:

```bash
make CC=clang
```

---

## Run

```bash
./polyinstall_python
```

With options:

```bash
./polyinstall_python --version 3.13.3 --prefix ~/.local/python3
```

| Flag | Default | Description |
|------|---------|-------------|
| `--version` | `3.13.3` | CPython version to install |
| `--prefix` | `$HOME/.local/python3` | Directory to install into |

---

## What it does

1. Checks that `curl`, `tar`, `make`, and a C compiler are available
2. Downloads the CPython source tarball from `python.org/ftp`
3. Downloads the corresponding `.sha256` checksum file
4. Verifies the tarball against the checksum using a hand-written SHA-256 implementation (no OpenSSL dependency)
5. Extracts the tarball to a temporary directory
6. Runs `./configure --enable-optimizations`, `make`, and `make install`
7. Appends `<prefix>/bin` to PATH in `~/.bashrc`, `~/.zshrc`, and `~/.zprofile` as appropriate
8. Cleans up all temporary files

---

## Clean

```bash
make clean
```
