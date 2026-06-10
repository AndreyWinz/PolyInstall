# PolyInstall

> Hand-crafted, cross-platform installers for programming languages — written from scratch, in any language.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Status](https://img.shields.io/badge/status-active%20development-green.svg)]()

---

## Overview

**PolyInstall** is a personal open-source project providing clean, hand-coded installers for a wide range of programming languages across Windows, macOS, and Linux.

Every installer in this repository is written from scratch — no borrowed code, no third-party installer frameworks. The language used to build an installer is intentionally decoupled from the language being installed: a C++ installer might be written in C, a Python installer in Rust, and so on. This is a deliberate design philosophy that keeps each installer self-contained and educational.

---

## Goals

- Provide reliable, minimal installers for popular programming languages
- Demonstrate that installers can be written in any sufficiently capable language
- Keep all code hand-authored and well-documented for learning purposes
- Support all three major desktop operating systems from a single repository

---

## Repository Structure

```
polyinstall/
├── installers/
│   ├── c/                  # Installer for the C language
│   │   ├── windows/
│   │   ├── macos/
│   │   └── linux/
│   ├── cpp/                # Installer for C++
│   ├── python/             # Installer for Python
│   ├── rust/               # Installer for Rust
│   └── .../                # More languages over time
├── shared/                 # Shared utilities used across installers
├── docs/                   # Documentation and design notes
├── .gitattributes
├── .gitignore
├── LICENSE
└── README.md
```

Each language directory contains platform-specific subdirectories. Inside each, you will find:
- The installer source code
- A `BUILD.md` explaining how to compile/run it
- Notes on which language was used to write that installer

---

## Supported Languages (Planned / In Progress)

| Language | Windows | macOS | Linux | Installer Written In |
|----------|---------|-------|-------|----------------------|
| C        | 🔧      | 🔧    | 🔧    | TBD                  |
| C++      | 🔧      | 🔧    | 🔧    | TBD                  |
| Python   | 🔧      | 🔧    | 🔧    | TBD                  |
| Rust     | 🔧      | 🔧    | 🔧    | TBD                  |
| Go       | 🔧      | 🔧    | 🔧    | TBD                  |

> ✅ Complete — 🔧 In Progress — 📋 Planned

This table will be updated as installers are completed.

---

## Design Philosophy

### Any language can install any language
There is no rule that says a Python installer must be written in Python. PolyInstall deliberately explores cross-language installer authorship. The installer for a given language is chosen based on what makes the most sense technically or what is most interesting to implement.

### No borrowed code
Every line in this repository is hand-written. No installer frameworks (NSIS, Inno Setup, WiX, etc.) are used. This keeps the project educational and ensures full understanding of what each installer does.

### Minimal dependencies
Installers aim to rely only on what is available in a standard build environment for the chosen implementation language. Heavy runtime dependencies are avoided wherever possible.

---

## Building an Installer

Each installer has its own `BUILD.md` with specific instructions. The general pattern is:

```bash
cd installers/<language>/<platform>
# Follow the instructions in BUILD.md
```

Prerequisites will vary per installer. Common requirements include a C compiler (GCC, Clang, or MSVC), standard build tools for the implementation language, and platform-specific SDKs where necessary.

---

## Contributing

This is a personal project and is not currently open to external contributions. However, feedback, suggestions, and issue reports are welcome via the [Issues](../../issues) tab.

---

## License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for full details.

---

## Author

Built and maintained as a personal project. All code is original and hand-written.
