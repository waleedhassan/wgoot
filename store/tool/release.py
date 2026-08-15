import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flutter_play import build as build_module
from flutter_play import config as config_module
from flutter_play import graphics, keystore, listing, preflight, screenshots, version
from flutter_play.log import ReleaseError, banner, fail, info, ok, result, step, warn


def _reconfigure_stdout():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass


def _targets(config, args):
    targets = []
    if config.get("build", "appbundle") and not args.apk_only:
        targets.append("appbundle")
    if config.get("build", "apk") or args.apk or args.apk_only:
        targets.append("apk")
    return targets or ["appbundle"]


def _ensure_keystore(config, assume_yes):
    if keystore.exists(config):
        return True
    warn("no release keystore is configured")
    info("Without one, Flutter signs the release with debug keys and Play rejects it.")
    if assume_yes or not sys.stdin.isatty():
        return False
    answer = input("create an upload keystore now? [Y/n]: ").strip().lower()
    if answer in ("", "y", "yes"):
        keystore.create(config)
        return True
    return False


def command_preflight(config, args):
    report = preflight.run(config, skip_slow=args.fast)
    return 0 if report.clean else 2


def command_keystore(config, args):
    keystore.create(config, force=args.force)
    return 0


def command_fingerprints(config, args):
    keystore.show(config)
    return 0


def command_graphics(config, args):
    graphics.generate(config)
    return 0


def command_screenshots(config, args):
    if args.capture:
        screenshots.capture(config, device_class=args.device_class, serial=args.serial)
    screenshots.process(config, device_class=args.device_class)
    return 0


def command_listing(config, args):
    listing.export(config)
    return 0


def command_version(config, args):
    current = config.pubspec["version"]
    if not args.set and not args.bump:
        result("version " + current)
        return 0
    version.apply(config, args.set, args.bump)
    return 0


def command_build(config, args):
    targets = _targets(config, args)
    if not args.no_clean:
        build_module.clean(config)
    for target in targets:
        build_module.build(config, target)
    signature = build_module.verify(config, targets)
    build_module.collect(config, targets, signature)
    return 0


def command_all(config, args):
    banner("release {0} {1}".format(config.pubspec["name"], config.pubspec["version"]))
    info("project " + config.root)
    if config.path:
        info("config  " + config.path)

    _ensure_keystore(config, args.yes)

    version.apply(config, args.set, args.bump)

    graphics_dir = os.path.join(config.store_dir, "graphics")
    if not os.path.isfile(os.path.join(graphics_dir, "icon-512.png")):
        try:
            graphics.generate(config)
        except ReleaseError as error:
            warn(str(error))

    report = preflight.run(config, skip_slow=True)
    if not report.clean and not args.force:
        banner("stopped")
        fail("preflight found blocking problems, nothing was built")
        info("Fix them, or re-run with --force to build anyway.")
        return 2

    targets = _targets(config, args)

    if not args.no_clean:
        build_module.clean(config)

    if not args.skip_checks:
        preflight.run_analyze(config, report)
        preflight.run_tests(config, report)
        if not report.clean and not args.force:
            banner("stopped")
            fail("analyze or tests failed, nothing was built")
            return 2

    for target in targets:
        build_module.build(config, target)

    signature = build_module.verify(config, targets)
    out = build_module.collect(config, targets, signature)

    try:
        listing.export(config)
    except ReleaseError as error:
        warn(str(error))

    banner("ready to upload")
    result(out)
    info("1. Play Console -> your app -> Production (or Internal testing) -> Create new release")
    info("2. Upload the .aab, then paste the release notes from this folder")
    info("3. Upload native-debug-symbols.zip if it is present")
    info("4. Store listing text and graphics live in " + config.store_dir)
    if report.warnings:
        info("")
        warn("{0} non-blocking warnings above are worth a read".format(len(report.warnings)))
    return 0


COMMANDS = {
    "preflight": command_preflight,
    "keystore": command_keystore,
    "fingerprints": command_fingerprints,
    "graphics": command_graphics,
    "listing": command_listing,
    "screenshots": command_screenshots,
    "build": command_build,
    "version": command_version,
    "all": command_all,
}

EPILOG = """\
commands:
  all            the full pipeline: checks, build, verify, collect (default)
  preflight      run the release checks only
  keystore       create the upload keystore and android/key.properties
  fingerprints   print the upload key SHA-1 and SHA-256
  graphics       generate the store icon and feature graphic
  screenshots    normalise screenshots, with --capture to grab them over adb
  listing        export paste-ready listing text
  build          build, verify and collect, skipping the checks
  version        show the version, or change it with --bump / --set

examples:
  release.py
  release.py --bump build
  release.py preflight --fast
  release.py screenshots --capture --class phone
  release.py build --no-clean --apk
"""


def build_parser():
    parser = argparse.ArgumentParser(
        prog="release.py",
        description="Prepare and build a Flutter app for the Google Play Store.",
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "command",
        nargs="?",
        default="all",
        choices=sorted(COMMANDS),
        help=argparse.SUPPRESS,
    )
    parser.add_argument("--config", help="path to release.toml")
    parser.add_argument("--project", help="path inside the Flutter project")
    parser.add_argument("--apk", action="store_true", help="also build a release APK")
    parser.add_argument("--apk-only", action="store_true", help="build only an APK")
    parser.add_argument("--no-clean", action="store_true", help="skip flutter clean")
    parser.add_argument("--skip-checks", action="store_true", help="skip analyze and tests")
    parser.add_argument("--force", action="store_true", help="proceed despite failed checks")
    parser.add_argument("--yes", action="store_true", help="never prompt")
    parser.add_argument("--fast", action="store_true", help="preflight: skip analyze and tests")
    parser.add_argument("--capture", action="store_true", help="screenshots: grab over adb")
    parser.add_argument(
        "--class",
        dest="device_class",
        default="phone",
        choices=screenshots.CLASSES,
        help="screenshots: device class",
    )
    parser.add_argument("--serial", help="screenshots: adb device serial")
    parser.add_argument("--bump", choices=["build", "patch", "minor", "major"])
    parser.add_argument("--set", help="set an explicit version, for example 1.2.0+7")

    return parser


def main(argv=None):
    _reconfigure_stdout()
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        config = config_module.load(args.config, args.project or os.getcwd())
    except ReleaseError as error:
        fail(str(error))
        return 1

    handler = COMMANDS.get(args.command or "all")
    try:
        return handler(config, args)
    except ReleaseError as error:
        banner("stopped")
        fail(str(error))
        return 1
    except KeyboardInterrupt:
        warn("interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())
