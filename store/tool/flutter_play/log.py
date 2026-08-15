import os
import sys

_COLOR = os.environ.get("NO_COLOR") is None and sys.stdout.isatty()

_RESET = "\033[0m" if _COLOR else ""
_DIM = "\033[2m" if _COLOR else ""
_RED = "\033[31m" if _COLOR else ""
_GREEN = "\033[32m" if _COLOR else ""
_YELLOW = "\033[33m" if _COLOR else ""
_BLUE = "\033[36m" if _COLOR else ""
_BOLD = "\033[1m" if _COLOR else ""


class ReleaseError(Exception):
    pass


def _write(text):
    try:
        sys.stdout.write(text + "\n")
    except UnicodeEncodeError:
        sys.stdout.write(text.encode("ascii", "replace").decode("ascii") + "\n")
    sys.stdout.flush()


def banner(text):
    _write("")
    _write(_BOLD + _BLUE + "== " + text + " " + "=" * max(0, 68 - len(text)) + _RESET)


def step(text):
    _write(_BLUE + "->" + _RESET + " " + text)


def ok(text):
    _write(_GREEN + "  OK" + _RESET + "  " + text)


def warn(text):
    _write(_YELLOW + "  WARN" + _RESET + "  " + text)


def fail(text):
    _write(_RED + "  FAIL" + _RESET + "  " + text)


def info(text):
    _write(_DIM + "       " + text + _RESET)


def result(text):
    _write(_BOLD + text + _RESET)
