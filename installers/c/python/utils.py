"""
utils.py — Shared utilities for the PolyInstall C installer (Python variant)

Covers: downloading files, SHA-256 and SHA-512 verification, tarball/zip
extraction, running subprocesses, and persistent PATH updates.
All crypto is implemented using Python's standard library hashlib only.
"""

import os
import sys
import shutil
import hashlib
import subprocess
import tempfile
import zipfile
import tarfile
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.error import URLError

from log import log, ok, warn, error

# ── Module-level temp dir ─────────────────────────────────────────────────────
_temp_dir: str = ""


def make_temp_dir() -> str:
    global _temp_dir
    _temp_dir = tempfile.mkdtemp(prefix="polyinstall_c_")
    return _temp_dir


def cleanup_temp_dir() -> None:
    global _temp_dir
    if _temp_dir and os.path.isdir(_temp_dir):
        log("Cleaning up temporary files...")
        shutil.rmtree(_temp_dir, ignore_errors=True)
        _temp_dir = ""


# ── Download ──────────────────────────────────────────────────────────────────
_CHUNK = 65536   # 64 KiB read chunks

def download(url: str, dest: str) -> None:
    """Download url to dest, showing a simple progress indicator."""
    log(f"Downloading: {url}")
    try:
        req = Request(url, headers={"User-Agent": "PolyInstall/1.0"})
        with urlopen(req) as resp, open(dest, "wb") as f:
            total = int(resp.headers.get("Content-Length", 0))
            downloaded = 0
            while True:
                chunk = resp.read(_CHUNK)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)
                if total:
                    pct = downloaded * 100 // total
                    print(f"\r  {pct:3d}%  {downloaded // 1024} KB / {total // 1024} KB",
                          end="", flush=True)
            print()   # newline after progress
    except URLError as exc:
        error(f"Download failed for {url}: {exc}")


# ── Checksum verification ─────────────────────────────────────────────────────

def _hash_file(path: str, algorithm: str) -> str:
    h = hashlib.new(algorithm)
    with open(path, "rb") as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def verify_sha256(file_path: str, checksum_source: str) -> None:
    """
    Verify file_path against a SHA-256 checksum.
    checksum_source can be a file path (read first token) or a raw hex string.
    """
    log("Verifying SHA-256 checksum...")
    if os.path.isfile(checksum_source):
        with open(checksum_source) as f:
            expected = f.read().split()[0].lower()
    else:
        expected = checksum_source.strip().lower()

    actual = _hash_file(file_path, "sha256")
    if expected != actual:
        error(
            f"Checksum mismatch!\n"
            f"  Expected: {expected}\n"
            f"  Got:      {actual}"
        )
    ok(f"SHA-256 verified: {actual}")


def verify_sha512_from_sumsfile(file_path: str, sums_file: str, filename: str) -> None:
    """
    Verify file_path against a GNU-style sha512.sum file, looking up `filename`.
    """
    log("Verifying SHA-512 checksum...")
    expected = None
    with open(sums_file) as f:
        for line in f:
            parts = line.split()
            # GNU sha512sum format: <hash>  <filename>
            if len(parts) >= 2 and parts[1].lstrip("*") == filename:
                expected = parts[0].lower()
                break
    if not expected:
        error(f"Could not find checksum for {filename} in {sums_file}")

    actual = _hash_file(file_path, "sha512")
    if expected != actual:
        error(
            f"Checksum mismatch!\n"
            f"  Expected: {expected}\n"
            f"  Got:      {actual}"
        )
    ok(f"SHA-512 verified: {actual}")


# ── Archive extraction ────────────────────────────────────────────────────────

def extract_tar(archive: str, dest_dir: str) -> None:
    log(f"Extracting {os.path.basename(archive)}...")
    with tarfile.open(archive) as tf:
        tf.extractall(path=dest_dir)
    ok(f"Extracted to {dest_dir}")


def extract_zip(archive: str, dest_dir: str) -> None:
    log(f"Extracting {os.path.basename(archive)}...")
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(path=dest_dir)
    ok(f"Extracted to {dest_dir}")


# ── Subprocess helper ─────────────────────────────────────────────────────────

def run(cmd: list[str], cwd: str | None = None, env: dict | None = None) -> None:
    """Run a command, streaming output; exits on non-zero return code."""
    display = " ".join(cmd)
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            env=env,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        error(f"Command failed (exit {exc.returncode}): {display}")
    except FileNotFoundError:
        error(f"Executable not found: {cmd[0]}")


def run_silent(cmd: list[str], cwd: str | None = None) -> int:
    """Run a command silently; return its exit code without raising."""
    try:
        result = subprocess.run(
            cmd, cwd=cwd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return result.returncode
    except FileNotFoundError:
        return 127


# ── PATH update helpers ───────────────────────────────────────────────────────

def _append_to_profile(profile: Path, bin_dir: str, label: str) -> None:
    """Append an export PATH line to a shell profile file if not already present."""
    if profile.exists():
        if bin_dir in profile.read_text():
            log(f"Already configured in {profile}, skipping.")
            return
    with profile.open("a") as f:
        f.write(f"\n# Added by PolyInstall — {label}\n")
        f.write(f'export PATH="{bin_dir}:$PATH"\n')
    log(f"PATH updated in {profile}")


def update_path_unix(bin_dir: str, label: str) -> None:
    home = Path.home()
    _append_to_profile(home / ".bashrc",   bin_dir, label)
    if (home / ".bash_profile").exists():
        _append_to_profile(home / ".bash_profile", bin_dir, label)
    if (home / ".zshrc").exists():
        _append_to_profile(home / ".zshrc",    bin_dir, label)
    if (home / ".zprofile").exists():
        _append_to_profile(home / ".zprofile", bin_dir, label)
    ok("PATH update complete.")


def update_path_windows(bin_dir: str) -> None:
    """Append bin_dir to the current user's PATH in the Windows registry."""
    import winreg
    key = winreg.OpenKey(
        winreg.HKEY_CURRENT_USER,
        r"Environment",
        0,
        winreg.KEY_READ | winreg.KEY_WRITE,
    )
    try:
        current, _ = winreg.QueryValueEx(key, "PATH")
    except FileNotFoundError:
        current = ""

    if bin_dir.lower() not in current.lower():
        new_path = f"{bin_dir};{current}" if current else bin_dir
        winreg.SetValueEx(key, "PATH", 0, winreg.REG_EXPAND_SZ, new_path)
        ok(f"Added to PATH: {bin_dir}")
    else:
        log(f"Already in PATH: {bin_dir}")
    winreg.CloseKey(key)
