import re

from .log import ReleaseError, ok, step

_SEMVER = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def parse(raw):
    if "+" in raw:
        name, build = raw.split("+", 1)
    else:
        name, build = raw, "0"
    match = _SEMVER.match(name.strip())
    if not match:
        raise ReleaseError(
            "version '{0}' is not MAJOR.MINOR.PATCH+BUILD".format(raw)
        )
    if not build.strip().isdigit():
        raise ReleaseError("build number '{0}' is not an integer".format(build))
    return (
        int(match.group(1)),
        int(match.group(2)),
        int(match.group(3)),
        int(build.strip()),
    )


def format_version(major, minor, patch, build):
    return "{0}.{1}.{2}+{3}".format(major, minor, patch, build)


def bumped(raw, part):
    major, minor, patch, build = parse(raw)
    if part == "build":
        return format_version(major, minor, patch, build + 1)
    if part == "patch":
        return format_version(major, minor, patch + 1, build + 1)
    if part == "minor":
        return format_version(major, minor + 1, 0, build + 1)
    if part == "major":
        return format_version(major + 1, 0, 0, build + 1)
    raise ReleaseError("unknown bump part: " + part)


def write(config, new_version):
    parse(new_version)
    path = config.resolve("pubspec.yaml")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()

    updated, count = re.subn(
        r"^version:\s*\S+",
        "version: " + new_version,
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise ReleaseError("could not rewrite 'version:' in pubspec.yaml")

    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(updated)

    config.pubspec = dict(config.pubspec)
    config.pubspec["version"] = new_version
    name, build = new_version.split("+", 1)
    config.pubspec["version_name"] = name
    config.pubspec["build_number"] = build
    return new_version


def apply(config, explicit, bump):
    current = config.pubspec["version"]
    if explicit:
        target = explicit
    elif bump:
        target = bumped(current, bump)
    else:
        return current

    if target == current:
        return current

    step("version {0} -> {1}".format(current, target))
    write(config, target)
    ok("pubspec.yaml updated")
    return target
