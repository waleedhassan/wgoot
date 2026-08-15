import getpass
import os
import re

from . import shell
from .log import ReleaseError, banner, fail, info, ok, step, warn

KEY_PROPERTIES = "android/key.properties"
DEFAULT_ALIAS = "upload"
DEFAULT_STORE = "upload-keystore.jks"


def properties_path(config):
    return config.resolve(KEY_PROPERTIES)


def read_properties(config):
    path = properties_path(config)
    if not os.path.isfile(path):
        return None
    values = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key.strip()] = value.strip()
    return values


def store_file(config, values):
    raw = values.get("storeFile")
    if not raw:
        return None
    if os.path.isabs(raw):
        return raw
    return os.path.normpath(os.path.join(config.resolve("android"), raw))


def exists(config):
    values = read_properties(config)
    if not values:
        return False
    path = store_file(config, values)
    return bool(path) and os.path.isfile(path)


def _prompt(text, default=""):
    suffix = " [{0}]: ".format(default) if default else ": "
    answer = input(text + suffix).strip()
    return answer or default


def _password(text):
    while True:
        first = getpass.getpass(text + ": ")
        if len(first) < 6:
            fail("password must be at least 6 characters")
            continue
        second = getpass.getpass("confirm: ")
        if first != second:
            fail("passwords did not match, try again")
            continue
        return first


def create(config, force=False):
    banner("upload keystore")

    path = properties_path(config)
    if os.path.isfile(path) and not force:
        values = read_properties(config)
        target = store_file(config, values)
        if target and os.path.isfile(target):
            ok("android/key.properties already points at " + target)
            return False
        warn("android/key.properties exists but the keystore file is missing")

    shell.require(
        "keytool",
        "Install a JDK (Android Studio ships one under jbr/bin) and put it on PATH.",
    )

    info("This creates the key that signs every future update of this app.")
    info("Losing it means you can no longer update the listing under the same app.")
    info("")

    keystore_name = _prompt("keystore file name", DEFAULT_STORE)
    keystore_path = os.path.join(config.resolve("android"), keystore_name)
    if os.path.exists(keystore_path) and not force:
        raise ReleaseError(
            "keystore already exists: {0} (pass --force to overwrite)".format(
                keystore_path
            )
        )

    alias = _prompt("key alias", DEFAULT_ALIAS)
    common_name = _prompt("your name or company (CN)", config.pubspec["name"])
    organisation = _prompt("organisation (O)", common_name)
    country = _prompt("two letter country code (C)", "SA")
    validity = _prompt("validity in days", "10000")

    password = _password("keystore password")

    dname = "CN={0}, O={1}, C={2}".format(common_name, organisation, country.upper())
    env = {"FLUTTER_PLAY_STOREPASS": password}

    step("generating " + keystore_path)
    shell.run(
        [
            "keytool",
            "-genkeypair",
            "-v",
            "-keystore",
            keystore_path,
            "-storetype",
            "PKCS12",
            "-keyalg",
            "RSA",
            "-keysize",
            "2048",
            "-validity",
            validity,
            "-alias",
            alias,
            "-dname",
            dname,
            "-storepass:env",
            "FLUTTER_PLAY_STOREPASS",
            "-keypass:env",
            "FLUTTER_PLAY_STOREPASS",
        ],
        env=env,
        capture=True,
    )
    ok("keystore created")

    content = (
        "storePassword={0}\n"
        "keyPassword={0}\n"
        "keyAlias={1}\n"
        "storeFile={2}\n"
    ).format(password, alias, keystore_name)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)
    ok("wrote android/key.properties")

    _ensure_ignored(config)

    warn("Back up " + keystore_path + " and its password somewhere safe and private.")
    warn("Never commit the keystore or key.properties to git.")
    return True


def _ensure_ignored(config):
    path = config.resolve(os.path.join("android", ".gitignore"))
    needed = ["key.properties", "**/*.keystore", "**/*.jks"]
    existing = ""
    if os.path.isfile(path):
        with open(path, encoding="utf-8") as handle:
            existing = handle.read()

    missing = [entry for entry in needed if entry not in existing]
    if not missing:
        return

    with open(path, "a", encoding="utf-8", newline="\n") as handle:
        handle.write("\n# Never publicly share your keystore.\n")
        for entry in missing:
            handle.write(entry + "\n")
    ok("added keystore entries to android/.gitignore")


def fingerprints(config):
    values = read_properties(config)
    if not values:
        raise ReleaseError("android/key.properties not found, run: release.py keystore")

    path = store_file(config, values)
    if not path or not os.path.isfile(path):
        raise ReleaseError("keystore file not found: " + str(path))

    shell.require("keytool", "Install a JDK and put keytool on PATH.")
    env = {"FLUTTER_PLAY_STOREPASS": values.get("storePassword", "")}
    text = shell.output(
        [
            "keytool",
            "-list",
            "-v",
            "-keystore",
            path,
            "-alias",
            values.get("keyAlias", DEFAULT_ALIAS),
            "-storepass:env",
            "FLUTTER_PLAY_STOREPASS",
        ],
        check=False,
    )
    if "SHA-256" not in text:
        raise ReleaseError("could not read the keystore, check the password in key.properties")
    return text


def show(config):
    banner("upload key fingerprints")
    text = fingerprints(config)
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith(("SHA1:", "SHA256:", "Valid from", "Owner:", "Alias name:")):
            info(stripped)
    ok("give the SHA-256 to any service that needs to verify your app signature")


def certificate_of(artifact):
    shell.require("keytool", "Install a JDK and put keytool on PATH.")
    return shell.output(["keytool", "-printcert", "-jarfile", artifact], check=False)


def assert_not_debug_signed(artifact):
    text = certificate_of(artifact)
    if not text.strip():
        warn("could not read the signing certificate of " + os.path.basename(artifact))
        return None
    owner = re.search(r"Owner:\s*(.+)", text)
    if owner and "Android Debug" in owner.group(1):
        raise ReleaseError(
            "{0} is signed with the Android debug key. Play will reject it. "
            "Run: release.py keystore".format(os.path.basename(artifact))
        )
    sha = re.search(r"SHA256:\s*([0-9A-F:]+)", text)
    if owner:
        info("signed by " + owner.group(1).strip())
    if sha:
        info("SHA-256 " + sha.group(1))
    return sha.group(1) if sha else None
