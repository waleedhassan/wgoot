import os
import re

from .log import ReleaseError

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None

DEFAULTS = {
    "build": {
        "appbundle": True,
        "apk": False,
        "split_per_abi": False,
        "obfuscate": True,
        "flavor": "",
        "dart_defines": [],
        "extra_args": [],
    },
    "checks": {
        "analyze": True,
        "test": True,
        "fatal_infos": False,
        "require_release_signing": True,
        "forbidden_application_ids": ["com.example", "com.yourcompany"],
        "allowed_permissions": [],
    },
    "output": {
        "dir": "build/play",
        "keep_versions": 10,
    },
    "store": {
        "dir": "store/play",
        "listing_locales": ["ar", "en-US"],
    },
    "graphics": {
        "background_start": "#7E5130",
        "background_end": "#2E1A0D",
        "accent": "#E0C177",
        "text": "#FAF2E2",
        "title": "",
        "subtitle": "",
        "font": "",
        "icon_source": "assets/icon/app_icon.png",
    },
}


def _merge(base, override):
    merged = dict(base)
    for key, value in override.items():
        if key in merged and isinstance(merged[key], dict) and isinstance(value, dict):
            merged[key] = _merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def find_project_root(start):
    current = os.path.abspath(start)
    while True:
        if os.path.isfile(os.path.join(current, "pubspec.yaml")):
            return current
        parent = os.path.dirname(current)
        if parent == current:
            raise ReleaseError(
                "no pubspec.yaml found in '{0}' or any parent directory".format(start)
            )
        current = parent


def read_pubspec(root):
    path = os.path.join(root, "pubspec.yaml")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()

    name = re.search(r"^name:\s*(\S+)", text, re.MULTILINE)
    version = re.search(r"^version:\s*(\S+)", text, re.MULTILINE)
    description = re.search(r"^description:\s*(.+)$", text, re.MULTILINE)

    if not name:
        raise ReleaseError("pubspec.yaml has no 'name:' field")
    if not version:
        raise ReleaseError("pubspec.yaml has no 'version:' field")

    raw = version.group(1).strip().strip("\"'")
    if "+" in raw:
        version_name, build_number = raw.split("+", 1)
    else:
        version_name, build_number = raw, ""

    summary = ""
    if description:
        summary = description.group(1).strip().strip("\"'")

    return {
        "name": name.group(1).strip().strip("\"'"),
        "description": summary,
        "version": raw,
        "version_name": version_name,
        "build_number": build_number,
    }


def read_application_id(root):
    candidates = [
        os.path.join(root, "android", "app", "build.gradle.kts"),
        os.path.join(root, "android", "app", "build.gradle"),
    ]
    for path in candidates:
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        match = re.search(r"applicationId\s*=?\s*[\"']([^\"']+)[\"']", text)
        if match:
            return match.group(1), path
    return None, None


class Config:
    def __init__(self, root, data, path):
        self.root = root
        self.data = data
        self.path = path
        self.pubspec = read_pubspec(root)
        self.application_id, self.gradle_file = read_application_id(root)

    def section(self, name):
        return self.data.get(name, {})

    def get(self, section, key):
        return self.data.get(section, {}).get(key)

    def resolve(self, relative):
        return os.path.normpath(os.path.join(self.root, relative))

    @property
    def output_dir(self):
        return self.resolve(self.get("output", "dir"))

    @property
    def store_dir(self):
        return self.resolve(self.get("store", "dir"))


def load(config_path=None, start=None):
    start = start or os.getcwd()

    if config_path:
        config_path = os.path.abspath(config_path)
        if not os.path.isfile(config_path):
            raise ReleaseError("config file not found: " + config_path)
    else:
        here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        candidate = os.path.join(here, "release.toml")
        config_path = candidate if os.path.isfile(candidate) else None

    data = DEFAULTS
    if config_path:
        if tomllib is None:
            raise ReleaseError("reading release.toml needs Python 3.11 or newer")
        with open(config_path, "rb") as handle:
            data = _merge(DEFAULTS, tomllib.load(handle))

    project = data.get("project", {}).get("root")
    if project:
        root = os.path.abspath(
            os.path.join(os.path.dirname(config_path or start), project)
        )
        root = find_project_root(root)
    else:
        root = find_project_root(start)

    return Config(root, data, config_path)
