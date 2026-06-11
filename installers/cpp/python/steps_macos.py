"""
steps_macos.py — macOS steps for the PolyInstall C++ installer (Python variant)
Installs Apple Clang++ via Xcode Command Line Tools.
Explicitly verifies clang++ (not just clang) before declaring success.
"""

import subprocess
import shutil
import time

from log import log, ok, warn, error
from utils import run_silent


def _clt_installed() -> bool:
    if run_silent(["xcode-select", "-p"]) != 0:
        return False
    # Verify clang++ specifically — it is always present alongside clang in CLT
    return shutil.which("clang++") is not None


def _clangpp_version() -> str:
    try:
        result = subprocess.run(
            ["clang++", "--version"],
            capture_output=True, text=True,
        )
        return result.stdout.splitlines()[0] if result.stdout else "unknown"
    except Exception:
        return "unknown"


def install_macos() -> None:
    log("Checking for Xcode Command Line Tools (clang++)...")

    if _clt_installed():
        path_result = subprocess.run(
            ["xcode-select", "-p"], capture_output=True, text=True
        )
        clt_path = path_result.stdout.strip()
        ok("Xcode Command Line Tools are already installed.")
        ok(f"Path:     {clt_path}")
        ok(f"clang++:  {_clangpp_version()}")
        print()
        print("  Verify C++ compilation with:")
        print(
            "  printf '#include<iostream>\\nint main()"
            "{std::cout<<\"hello\\\\n\";}\\n'"
            " | clang++ -x c++ - -o /tmp/hi && /tmp/hi"
        )
        print()
        return

    log("Xcode Command Line Tools not found. Triggering installation prompt...")
    print()
    warn("A system dialog will appear — click 'Install' (not 'Get Xcode').")
    warn("This installer will poll every 15 seconds and continue automatically.")
    print()

    subprocess.run(
        ["xcode-select", "--install"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    log("Waiting for Xcode Command Line Tools installation to complete...")

    timeout  = 1800
    interval = 15
    elapsed  = 0

    while not _clt_installed():
        if elapsed >= timeout:
            error("Timed out waiting for Xcode Command Line Tools installation.")
        time.sleep(interval)
        elapsed += interval
        log(f"Still waiting... ({elapsed}s elapsed)")

    time.sleep(5)

    if not _clt_installed():
        error(
            "Installation appeared to complete but 'clang++' is not available.\n"
            "Try opening a new terminal and running: clang++ --version"
        )

    path_result = subprocess.run(
        ["xcode-select", "-p"], capture_output=True, text=True
    )
    clt_path = path_result.stdout.strip()

    ok("Xcode Command Line Tools installed successfully.")
    ok(f"Path:     {clt_path}")
    ok(f"clang++:  {_clangpp_version()}")
    print()
    print("  Verify C++ compilation with:")
    print(
        "  printf '#include<iostream>\\nint main()"
        "{std::cout<<\"hello\\\\n\";}\\n'"
        " | clang++ -x c++ - -o /tmp/hi && /tmp/hi"
    )
    print()
