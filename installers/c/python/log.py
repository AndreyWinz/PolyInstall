"""
log.py — Logging helpers for the PolyInstall C installer (Python variant)
"""

import sys
import os

# Detect colour support: enable only when outputting to a real terminal
_USE_COLOUR = sys.stdout.isatty() and os.name != "nt"

_CYAN  = "\033[0;36m"
_GREEN = "\033[0;32m"
_RED   = "\033[0;31m"
_YELLOW = "\033[0;33m"
_BOLD  = "\033[1m"
_RESET = "\033[0m"


def _prefix(colour: str, tag: str) -> str:
    if _USE_COLOUR:
        return f"{colour}{_BOLD}{tag}{_RESET}"
    return tag


def log(msg: str) -> None:
    print(f"{_prefix(_CYAN, '[polyinstall]')} {msg}")


def ok(msg: str) -> None:
    print(f"{_prefix(_GREEN, '[ok]')} {msg}")


def warn(msg: str) -> None:
    print(f"{_prefix(_YELLOW, '[warn]')} {msg}", file=sys.stderr)


def error(msg: str) -> None:
    print(f"{_prefix(_RED, '[error]')} {msg}", file=sys.stderr)
    sys.exit(1)
