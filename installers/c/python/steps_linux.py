"""
steps_linux.py — Linux installation steps for the PolyInstall C installer
Downloads GCC from ftp.gnu.org, verifies SHA-512, builds from source.
"""

import os
import shutil
from pathlib import Path

from log import log, ok, warn, error
from utils import (
    make_temp_dir, cleanup_temp_dir,
    download, verify_sha512_from_sumsfile,
    extract_tar, run, run_silent,
    update_path_unix,
)

# ── Dependency check ──────────────────────────────────────────────────────────
_REQUIRED = ["curl", "tar", "make"]
_COMPILERS = ["gcc", "cc", "clang"]
_MATH_LIBS_HINT = (
    "GCC requires GMP, MPFR, and MPC development headers.\n"
    "  Debian/Ubuntu: sudo apt install libgmp-dev libmpfr-dev libmpc-dev\n"
    "  Fedora/RHEL:   sudo dnf install gmp-devel mpfr-devel libmpc-devel"
)

def _check_deps() -> None:
    log("Checking dependencies...")
    missing = [t for t in _REQUIRED if shutil.which(t) is None]
    if missing:
        error(f"Missing required tools: {', '.join(missing)}")

    has_compiler = any(shutil.which(c) for c in _COMPILERS)
    if not has_compiler:
        error(
            "No C compiler found (needed to bootstrap GCC).\n"
            "  Debian/Ubuntu: sudo apt install build-essential\n"
            "  Fedora/RHEL:   sudo dnf install gcc"
        )
    ok("All dependencies present.")


# ── CPU count ─────────────────────────────────────────────────────────────────
def _cpu_count() -> int:
    try:
        return os.cpu_count() or 2
    except Exception:
        return 2


# ── Main Linux install ────────────────────────────────────────────────────────
def install_linux(version: str, prefix: str | None) -> None:
    if prefix is None:
        prefix = str(Path.home() / ".local" / "gcc")

    log(f"Target: GCC {version} → {prefix}")

    _check_deps()

    temp = make_temp_dir()
    tarball_name = f"gcc-{version}.tar.xz"
    sums_name    = "sha512.sum"
    base_url     = f"https://ftp.gnu.org/gnu/gcc/gcc-{version}"

    tarball_path = os.path.join(temp, tarball_name)
    sums_path    = os.path.join(temp, sums_name)
    source_dir   = os.path.join(temp, f"gcc-{version}")
    build_dir    = os.path.join(temp, "gcc-build")

    # ── Download ───────────────────────────────────────────────────────────────
    log(f"Downloading GCC {version}...")
    download(f"{base_url}/{tarball_name}", tarball_path)

    log("Downloading SHA-512 sums...")
    download(f"{base_url}/{sums_name}", sums_path)

    # ── Verify ─────────────────────────────────────────────────────────────────
    verify_sha512_from_sumsfile(tarball_path, sums_path, tarball_name)

    # ── Extract ────────────────────────────────────────────────────────────────
    extract_tar(tarball_path, temp)

    # ── Download GCC prerequisites (GMP, MPFR, MPC) ────────────────────────────
    log("Downloading GCC prerequisites (GMP, MPFR, MPC)...")
    run(["./contrib/download_prerequisites"], cwd=source_dir)
    ok("Prerequisites ready.")

    # ── Configure ──────────────────────────────────────────────────────────────
    log(f"Configuring GCC build (prefix: {prefix})...")
    os.makedirs(build_dir, exist_ok=True)
    run(
        [
            f"{source_dir}/configure",
            f"--prefix={prefix}",
            "--enable-languages=c",
            "--disable-multilib",
            "--disable-bootstrap",
            "--quiet",
        ],
        cwd=build_dir,
    )

    # ── Build ──────────────────────────────────────────────────────────────────
    jobs = _cpu_count()
    log(f"Building GCC (using {jobs} jobs — this will take a while)...")
    run(["make", f"-j{jobs}", "--quiet"], cwd=build_dir)

    # ── Install ────────────────────────────────────────────────────────────────
    log(f"Installing to {prefix}...")
    run(["make", "install", "--quiet"], cwd=build_dir)
    ok(f"GCC {version} installed.")

    # ── PATH ───────────────────────────────────────────────────────────────────
    bin_dir = os.path.join(prefix, "bin")
    update_path_unix(bin_dir, f"GCC {version}")

    # ── Cleanup ────────────────────────────────────────────────────────────────
    cleanup_temp_dir()

    ok(f"C (GCC {version}) installed successfully to {prefix}")
    print()
    print("  Run:    source ~/.bashrc  (or open a new terminal)")
    print("  Verify: gcc --version")
    print()
