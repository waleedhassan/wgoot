import os
import shutil
import subprocess
import sys

from .log import ReleaseError, info


def which(name):
    found = shutil.which(name)
    if found:
        return found
    if os.name == "nt":
        for suffix in (".bat", ".cmd", ".exe"):
            found = shutil.which(name + suffix)
            if found:
                return found
    return None


def require(name, hint):
    found = which(name)
    if not found:
        raise ReleaseError("'{0}' was not found on PATH. {1}".format(name, hint))
    return found


def run(args, cwd=None, check=True, capture=False, env=None):
    executable = which(args[0])
    if executable is None:
        raise ReleaseError("command not found: " + args[0])
    command = [executable] + list(args[1:])

    merged = None
    if env:
        merged = dict(os.environ)
        merged.update(env)

    if capture:
        completed = subprocess.run(
            command,
            cwd=cwd,
            env=merged,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    else:
        info("$ " + " ".join(args))
        completed = subprocess.run(command, cwd=cwd, env=merged)

    if check and completed.returncode != 0:
        if capture and completed.stdout:
            sys.stdout.write(completed.stdout + "\n")
        raise ReleaseError(
            "command failed ({0}): {1}".format(completed.returncode, " ".join(args))
        )
    return completed


def output(args, cwd=None, check=True):
    completed = run(args, cwd=cwd, check=check, capture=True)
    return completed.stdout or ""
