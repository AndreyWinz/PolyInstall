"""
steps_windows.py — Windows steps for the PolyInstall C++ installer (Python variant)
Downloads LLVM/Clang from official GitHub releases (includes clang++).
Explicitly verifies clang++.exe before declaring success.
"""

import os
import shutil
import subprocess
from pathlib import Path

from log import log, ok, warn, error
from utils import (
    make_temp_dir, cleanup_temp_dir,
    download, verify_sha256,
    extract_zip, update_path_windows,
)


def install_windows(version: str, prefix: str | None) -> None:
    if prefix is None:
        prefix = str(Path.home() / ".local" / "llvm")

    log(f"Target: LLVM/Clang {version} (includes clang++) -> {prefix}")

    temp = make_temp_dir()

    zip_name      = f"LLVM-{version}-win64.zip"
    checksum_name = f"LLVM-{version}-win64.zip.sha256"
    base_url      = f"https://github.com/llvm/llvm-project/releases/download/llvmorg-{version}"

    zip_path      = os.path.join(temp, zip_name)
    checksum_path = os.path.join(temp, checksum_name)

    # Download
    log(f"Downloading LLVM/Clang {version} for Windows x64...")
    download(f"{base_url}/{zip_name}", zip_path)

    log("Downloading checksum...")
    download(f"{base_url}/{checksum_name}", checksum_path)

    # Verify
    verify_sha256(zip_path, checksum_path)

    # Extract
    log(f"Extracting to {prefix}...")
    if os.path.exists(prefix):
        log("Destination already exists — removing old installation...")
        shutil.rmtree(prefix)
    os.makedirs(prefix, exist_ok=True)

    extract_zip(zip_path, prefix)

    # Flatten single nested subdirectory if present
    entries = list(Path(prefix).iterdir())
    if len(entries) == 1 and entries[0].is_dir():
        inner = entries[0]
        for item in inner.iterdir():
            shutil.move(str(item), prefix)
        inner.rmdir()

    # Verify both compiler binaries explicitly
    clang_exe   = Path(prefix) / "bin" / "clang.exe"
    clangpp_exe = Path(prefix) / "bin" / "clang++.exe"

    if not clang_exe.exists():
        error(f"clang.exe not found at expected path: {clang_exe}")
    if not clangpp_exe.exists():
        error(f"clang++.exe not found at expected path: {clangpp_exe}")

    # PATH
    bin_dir = str(Path(prefix) / "bin")
    log("Updating user PATH...")
    update_path_windows(bin_dir)
    os.environ["PATH"] = f"{bin_dir};{os.environ.get('PATH', '')}"

    # Cleanup
    cleanup_temp_dir()

    # Version info
    def _ver(exe: Path) -> str:
        try:
            r = subprocess.run([str(exe), "--version"], capture_output=True, text=True)
            return r.stdout.splitlines()[0] if r.stdout else "unknown"
        except Exception:
            return "unknown"

    ok(f"LLVM/Clang {version} installed successfully to {prefix}")
    ok(f"clang:   {_ver(clang_exe)}")
    ok(f"clang++: {_ver(clangpp_exe)}")
    print()
    print("  Verify with: clang++ --version")
    print("  Note: Open a new terminal for PATH changes to take full effect.")
    print()
