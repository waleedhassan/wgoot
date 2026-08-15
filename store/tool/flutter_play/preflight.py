import os
import re
import xml.etree.ElementTree as ElementTree

from . import keystore, shell, version
from .log import ReleaseError, banner, fail, info, ok, step, warn

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

LISTING_LIMITS = {
    "title": 30,
    "short_description": 80,
    "full_description": 4000,
}
RELEASE_NOTES_LIMIT = 500
MIN_TARGET_SDK = 35

RESTRICTED_PERMISSIONS = {
    "android.permission.SCHEDULE_EXACT_ALARM": (
        "Play asks you to justify exact alarms. Eligible only if precise timing is a "
        "core user-facing feature (alarm clock, calendar, reminders)."
    ),
    "android.permission.USE_EXACT_ALARM": (
        "Restricted to alarm clock and calendar apps. Requires a Play Console declaration."
    ),
    "android.permission.QUERY_ALL_PACKAGES": (
        "Requires a Play Console declaration and is rarely approved."
    ),
    "android.permission.MANAGE_EXTERNAL_STORAGE": (
        "Requires a Play Console declaration with a demo video."
    ),
    "android.permission.REQUEST_INSTALL_PACKAGES": (
        "Requires a Play Console declaration."
    ),
    "android.permission.ACCESS_BACKGROUND_LOCATION": (
        "Requires a Play Console declaration with a demo video."
    ),
    "android.permission.READ_SMS": ("Restricted, requires a Play Console declaration."),
    "android.permission.RECEIVE_SMS": ("Restricted, requires a Play Console declaration."),
    "android.permission.READ_CALL_LOG": ("Restricted, requires a Play Console declaration."),
    "android.permission.CAMERA": ("Must be disclosed in Data safety if media leaves the device."),
    "android.permission.RECORD_AUDIO": ("Must be disclosed in Data safety."),
}


class Report:
    def __init__(self):
        self.failures = []
        self.warnings = []
        self.passes = 0

    def check(self, condition, message, remedy=None, otherwise=None):
        if condition:
            self.passes += 1
            ok(message)
        else:
            text = otherwise or message
            self.failures.append((text, remedy))
            fail(text)
            if remedy:
                info(remedy)
        return condition

    def advise(self, condition, message, remedy=None, otherwise=None):
        if condition:
            self.passes += 1
            ok(message)
        else:
            text = otherwise or message
            self.warnings.append((text, remedy))
            warn(text)
            if remedy:
                info(remedy)
        return condition

    def note(self, message):
        info(message)

    @property
    def clean(self):
        return not self.failures


def _read(path):
    if not os.path.isfile(path):
        return ""
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def _manifest(config):
    path = config.resolve("android/app/src/main/AndroidManifest.xml")
    if not os.path.isfile(path):
        raise ReleaseError("AndroidManifest.xml not found at " + path)
    return path, ElementTree.parse(path).getroot()


def _permissions(root):
    names = []
    for node in root.findall("uses-permission"):
        name = node.get(ANDROID_NS + "name")
        if name:
            names.append(name)
    for node in root.findall("uses-permission-sdk-23"):
        name = node.get(ANDROID_NS + "name")
        if name:
            names.append(name)
    return names


def check_toolchain(report):
    step("toolchain")
    flutter = shell.which("flutter")
    report.check(
        flutter is not None,
        "flutter is on PATH",
        "Install the Flutter SDK and add its bin directory to PATH.",
    )
    if flutter:
        text = shell.output(["flutter", "--version"], check=False)
        first = text.strip().splitlines()[0] if text.strip() else ""
        report.note(first)
    report.advise(
        shell.which("keytool") is not None,
        "keytool is on PATH",
        "Needed to create and inspect the upload keystore. Ships with any JDK.",
    )


def check_version(config, report):
    step("version")
    raw = config.pubspec["version"]
    try:
        major, minor, patch, build = version.parse(raw)
        report.check(True, "pubspec version is " + raw)
        report.check(
            build > 0,
            "versionCode (build number) is {0}".format(build),
            "Play needs a build number of at least 1, and it must increase every upload.",
        )
        report.note(
            "Play sees versionCode {0} and versionName {1}.{2}.{3}".format(
                build, major, minor, patch
            )
        )
    except ReleaseError as error:
        report.check(False, str(error), "Use the form 1.0.0+1 in pubspec.yaml.")


def check_application_id(config, report):
    step("application id")
    application_id = config.application_id
    report.check(
        bool(application_id),
        "applicationId found in " + str(config.gradle_file),
        "Set applicationId in android/app/build.gradle.kts.",
    )
    if not application_id:
        return

    report.note("applicationId = " + application_id)
    forbidden = config.get("checks", "forbidden_application_ids") or []
    bad = [prefix for prefix in forbidden if application_id.startswith(prefix)]
    report.check(
        not bad,
        "applicationId is not a template placeholder",
        "Play permanently rejects ids starting with " + ", ".join(bad) + ".",
    )
    report.check(
        bool(re.match(r"^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$", application_id)),
        "applicationId looks like a reverse-domain name",
        "Use lowercase reverse-domain form, for example com.yourdomain.yourapp.",
    )
    report.note("The applicationId can never be changed once the app is published.")


def check_signing(config, report):
    step("release signing")
    gradle = _read(config.gradle_file) if config.gradle_file else ""
    required = config.get("checks", "require_release_signing")

    has_config = "signingConfigs" in gradle and "release" in gradle
    report.advise(
        has_config,
        "build.gradle wires a release signingConfig",
        "Add a signingConfigs.release block that reads android/key.properties.",
    )

    present = keystore.exists(config)
    if required:
        report.check(
            present,
            "android/key.properties points at a real keystore",
            "Run: python store/tool/release.py keystore",
        )
    else:
        report.advise(present, "android/key.properties points at a real keystore")

    debug_fallback = "signingConfigs.getByName(\"debug\")" in gradle
    if present and debug_fallback:
        report.note("Gradle falls back to debug keys only when key.properties is absent.")

    tracked = _git_tracked(config, ["android/key.properties"])
    report.check(
        not tracked,
        "key.properties is not tracked by git",
        "Run: git rm --cached android/key.properties",
    )
    keystores = _git_tracked_glob(config, (".jks", ".keystore"))
    report.check(
        not keystores,
        "no keystore file is tracked by git",
        "Tracked: " + ", ".join(keystores),
    )


def _git_tracked(config, paths):
    if not shell.which("git"):
        return []
    text = shell.output(["git", "ls-files", "--"] + paths, cwd=config.root, check=False)
    return [line for line in text.splitlines() if line.strip()]


def _git_tracked_glob(config, suffixes):
    if not shell.which("git"):
        return []
    text = shell.output(["git", "ls-files"], cwd=config.root, check=False)
    return [
        line.strip()
        for line in text.splitlines()
        if line.strip().lower().endswith(suffixes)
    ]


def check_manifest(config, report):
    step("android manifest")
    path, root = _manifest(config)
    application = root.find("application")

    label = application.get(ANDROID_NS + "label") if application is not None else None
    report.check(
        bool(label),
        "application has android:label",
        "Set android:label so the launcher shows a real name.",
    )

    debuggable = application.get(ANDROID_NS + "debuggable") if application is not None else None
    report.check(
        debuggable != "true",
        "android:debuggable is not forced on",
        "Remove android:debuggable=\"true\" from the main manifest.",
    )

    icon = application.get(ANDROID_NS + "icon") if application is not None else None
    report.check(bool(icon), "application has android:icon")

    launcher = False
    for activity in application.findall("activity") if application is not None else []:
        for intent in activity.findall("intent-filter"):
            actions = {node.get(ANDROID_NS + "name") for node in intent.findall("action")}
            categories = {node.get(ANDROID_NS + "name") for node in intent.findall("category")}
            if (
                "android.intent.action.MAIN" in actions
                and "android.intent.category.LAUNCHER" in categories
            ):
                launcher = True
    report.check(launcher, "a LAUNCHER activity is declared")

    permissions = _permissions(root)
    report.note(
        "release permissions: " + (", ".join(sorted(permissions)) or "none")
    )
    if "android.permission.INTERNET" in permissions:
        report.advise(
            False,
            "INTERNET is requested in the release manifest",
            "Expected for online apps. For an offline app, keep it in "
            "src/debug/AndroidManifest.xml so the Data safety form stays honest.",
        )
    else:
        report.advise(True, "the release manifest does not request INTERNET")

    for name in permissions:
        if name in RESTRICTED_PERMISSIONS:
            report.warnings.append((name + " needs a Play declaration", RESTRICTED_PERMISSIONS[name]))
            warn(name + " needs a Play Console declaration")
            info(RESTRICTED_PERMISSIONS[name])

    allowed = config.get("checks", "allowed_permissions") or []
    if allowed:
        unexpected = [name for name in permissions if name not in allowed]
        report.check(
            not unexpected,
            "no unexpected permissions crept in",
            "Not in release.toml allowed_permissions: " + ", ".join(unexpected),
        )


def check_target_sdk(config, report):
    step("sdk levels")
    gradle = _read(config.gradle_file) if config.gradle_file else ""
    match = re.search(r"targetSdk\s*=?\s*(\d+)", gradle)
    if match:
        target = int(match.group(1))
        report.check(
            target >= MIN_TARGET_SDK,
            "targetSdk is {0}".format(target),
            "Play requires targetSdk {0} or higher for new apps and updates.".format(
                MIN_TARGET_SDK
            ),
        )
    elif "flutter.targetSdkVersion" in gradle:
        report.advise(
            True,
            "targetSdk follows the Flutter SDK default",
            "Confirm your Flutter version targets API {0} or higher.".format(MIN_TARGET_SDK),
        )
    else:
        report.advise(False, "could not determine targetSdk")


def check_icons(config, report):
    step("launcher icon")
    res = config.resolve("android/app/src/main/res")
    densities = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]
    missing = [
        density
        for density in densities
        if not os.path.isfile(os.path.join(res, "mipmap-" + density, "ic_launcher.png"))
    ]
    report.check(
        not missing,
        "launcher icons exist for every density",
        "Missing mipmap-" + ", mipmap-".join(missing),
    )
    adaptive = os.path.join(res, "mipmap-anydpi-v26", "ic_launcher.xml")
    report.advise(
        os.path.isfile(adaptive),
        "an adaptive icon is defined",
        "Android 8+ crops non-adaptive icons. Add mipmap-anydpi-v26/ic_launcher.xml.",
    )


def _listing_files(config):
    store = config.store_dir
    locales = config.get("store", "listing_locales") or []
    return [(locale, os.path.join(store, "listing", locale + ".md")) for locale in locales]


def _field(text, name):
    pattern = r"^##\s+" + name + r"\s*$\n(.*?)(?=^##\s|\Z)"
    match = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if not match:
        return None
    body = match.group(1)
    body = re.sub(r"^\s*<!--.*?-->\s*$", "", body, flags=re.MULTILINE | re.DOTALL)
    return body.strip()


def check_listing(config, report):
    step("store listing")
    files = _listing_files(config)
    if not files:
        report.advise(False, "no listing locales configured")
        return

    for locale, path in files:
        if not os.path.isfile(path):
            report.check(False, "listing missing for " + locale, "Expected " + path)
            continue

        text = _read(path)
        for field, limit in LISTING_LIMITS.items():
            value = _field(text, field)
            if value is None:
                report.check(
                    False,
                    "{0}: '## {1}' section missing".format(locale, field),
                    "Add a '## {0}' heading to {1}".format(field, path),
                )
                continue
            length = len(value)
            report.check(
                0 < length <= limit,
                "{0}: {1} is {2}/{3} characters".format(locale, field, length, limit),
                "Play truncates or rejects anything over the limit.",
            )
            if "TODO" in value:
                report.check(False, "{0}: {1} still contains TODO".format(locale, field))


def check_release_notes(config, report):
    step("release notes")
    directory = os.path.join(config.store_dir, "release-notes")
    if not os.path.isdir(directory):
        report.advise(False, "no release-notes directory", "Expected " + directory)
        return

    target = config.pubspec["version_name"]
    locales = config.get("store", "listing_locales") or []
    for locale in locales:
        path = os.path.join(directory, "{0}-{1}.txt".format(target, locale))
        if not os.path.isfile(path):
            report.advise(
                False,
                "no release notes for {0} {1}".format(target, locale),
                "Create " + path,
            )
            continue
        length = len(_read(path).strip())
        report.check(
            0 < length <= RELEASE_NOTES_LIMIT,
            "{0} {1}: {2}/{3} characters".format(target, locale, length, RELEASE_NOTES_LIMIT),
        )


def check_policy(config, report):
    step("policy documents")
    policy = os.path.join(config.store_dir, "policy")
    expected = {
        "privacy-policy.html": "Play requires a public URL to a privacy policy.",
        "data-safety.md": "Answers for the Data safety form.",
        "content-rating.md": "Answers for the IARC content rating questionnaire.",
        "app-content.md": "Ads, target audience and other App content declarations.",
    }
    for name, why in expected.items():
        report.advise(
            os.path.isfile(os.path.join(policy, name)),
            "policy/" + name + " is present",
            why,
            otherwise="policy/" + name + " is missing",
        )


def check_graphics(config, report):
    step("store graphics")
    graphics = os.path.join(config.store_dir, "graphics")
    report.advise(
        os.path.isfile(os.path.join(graphics, "icon-512.png")),
        "icon-512.png is present",
        "Run: python store/tool/release.py graphics",
        otherwise="icon-512.png is missing",
    )
    report.advise(
        os.path.isfile(os.path.join(graphics, "feature-graphic-1024x500.png")),
        "feature-graphic-1024x500.png is present",
        "Run: python store/tool/release.py graphics",
        otherwise="feature-graphic-1024x500.png is missing",
    )

    shots = os.path.join(graphics, "screenshots", "phone")
    count = 0
    if os.path.isdir(shots):
        count = len([n for n in os.listdir(shots) if n.lower().endswith(".png")])
    report.advise(
        count >= 2,
        "{0} phone screenshots ready".format(count),
        "Play requires at least 2 phone screenshots. "
        "Run: python store/tool/release.py screenshots --capture",
    )


def run_analyze(config, report):
    if not config.get("checks", "analyze"):
        return
    step("flutter analyze")
    args = ["flutter", "analyze"]
    if config.get("checks", "fatal_infos"):
        args.append("--fatal-infos")
    completed = shell.run(args, cwd=config.root, check=False)
    report.check(completed.returncode == 0, "flutter analyze is clean")


def run_tests(config, report):
    if not config.get("checks", "test"):
        return
    if not os.path.isdir(config.resolve("test")):
        report.advise(False, "no test directory")
        return
    step("flutter test")
    completed = shell.run(["flutter", "test"], cwd=config.root, check=False)
    report.check(completed.returncode == 0, "flutter test passes")


def run(config, skip_slow=False):
    banner("preflight")
    report = Report()

    check_toolchain(report)
    check_version(config, report)
    check_application_id(config, report)
    check_signing(config, report)
    check_manifest(config, report)
    check_target_sdk(config, report)
    check_icons(config, report)
    check_listing(config, report)
    check_release_notes(config, report)
    check_policy(config, report)
    check_graphics(config, report)

    if not skip_slow:
        run_analyze(config, report)
        run_tests(config, report)

    banner("preflight summary")
    info("{0} passed, {1} warnings, {2} blocking".format(
        report.passes, len(report.warnings), len(report.failures)
    ))
    if report.failures:
        for message, remedy in report.failures:
            fail(message)
            if remedy:
                info(remedy)
    return report
