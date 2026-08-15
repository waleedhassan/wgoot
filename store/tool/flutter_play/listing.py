import os
import re

from .log import ReleaseError, banner, info, ok, step, warn

FIELDS = (
    ("title", 30),
    ("short_description", 80),
    ("full_description", 4000),
)


def _read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def parse(path):
    text = _read(path)
    values = {}
    for name, _ in FIELDS:
        pattern = r"^##\s+" + name + r"\s*$\n(.*?)(?=^##\s|\Z)"
        match = re.search(pattern, text, re.MULTILINE | re.DOTALL)
        values[name] = match.group(1).strip() if match else None
    return values


def export(config):
    banner("store listing")

    locales = config.get("store", "listing_locales") or []
    source = os.path.join(config.store_dir, "listing")
    out = os.path.join(
        config.output_dir, config.pubspec["version"].replace("+", "-"), "listing"
    )
    os.makedirs(out, exist_ok=True)

    written = []
    for locale in locales:
        path = os.path.join(source, locale + ".md")
        if not os.path.isfile(path):
            warn("missing " + path)
            continue

        step(locale)
        values = parse(path)
        for name, limit in FIELDS:
            value = values.get(name)
            if value is None:
                raise ReleaseError(
                    "'## {0}' section missing in {1}".format(name, path)
                )
            length = len(value)
            if length > limit:
                warn("{0} {1}: {2}/{3} characters, over the limit".format(
                    locale, name, length, limit
                ))
            else:
                ok("{0}: {1}/{2}".format(name, length, limit))

            destination = os.path.join(out, "{0}.{1}.txt".format(locale, name))
            with open(destination, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(value + "\n")
            written.append(destination)

    info("paste-ready text in " + out)
    return written
