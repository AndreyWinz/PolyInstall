#!/usr/bin/env python3
"""
=============================================================================
PolyInstall — C Installer (written in Python)
main.py — Entry point and orchestration
=============================================================================
Detects the host platform, then downloads, verifies, extracts, and installs
a C compiler:
  - Linux   → GCC (built from source, from ftp.gnu.org)
  - macOS   → Apple Clang via Xcode Command Line Tools
  - Windows → LLVM/Clang pre-built binary (from github.com/llvm)

Usage:
  python3 main.py [--version <x.y.z>] [--prefix <dir>]

The --version flag sets the GCC version on Linux or the LLVM version on
Windows. It has no effect on macOS (CLT version is managed by Apple).
=============================================================================
"""

import sys
import platform
import argparse

from log import log, ok, error
from steps_linux  import install_linux
from steps_macos  import install_macos
from steps_windows import install_windows

# ── Argument parsing ──────────────────────────────────────────────────────────
def parse_args():
    parser = argparse.ArgumentParser(
        description="PolyInstall — C compiler installer (Python variant)"
    )
    parser.add_argument(
        "--version",
        default=None,
        help=(
            "Compiler version to install. "
            "Linux default: 14.2.0 (GCC). "
            "Windows default: 18.1.8 (LLVM/Clang). "
            "Ignored on macOS."
        ),
    )
    parser.add_argument(
        "--prefix",
        default=None,
        help=(
            "Directory to install into. "
            "Linux default: ~/.local/gcc. "
            "Windows default: %%USERPROFILE%%\\.local\\llvm. "
            "Ignored on macOS (CLT installs to a fixed Apple path)."
        ),
    )
    return parser.parse_args()


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    args = parse_args()
    system = platform.system()

    print()
    log("PolyInstall — C Installer (Python variant)")
    log(f"Platform: {system} ({platform.machine()})")
    print()

    if system == "Linux":
        install_linux(
            version=args.version or "14.2.0",
            prefix=args.prefix  or None,   # steps_linux resolves the default
        )
    elif system == "Darwin":
        if args.version:
            log("Note: --version is ignored on macOS (CLT version is managed by Apple).")
        if args.prefix:
            log("Note: --prefix is ignored on macOS (CLT installs to a fixed Apple path).")
        install_macos()
    elif system == "Windows":
        install_windows(
            version=args.version or "18.1.8",
            prefix=args.prefix  or None,
        )
    else:
        error(f"Unsupported platform: {system}")


if __name__ == "__main__":
    main()
