import glob
import hashlib
import json
import os
import shutil
import time
import zipfile

from . import keystore, shell
from .log import ReleaseError, banner, info, ok, step, warn


def _flutter_args(config, target):
    args = ["flutter", "build", target, "--release"]

    flavor = config.get("build", "flavor")
    if flavor:
        args += ["--flavor", flavor]

    for define in config.get("build", "dart_defines") or []:
        args += ["--dart-define", define]

    if config.get("build", "obfuscate"):
        args += [
            "--obfuscate",
            "--split-debug-info=" + os.path.join("build", "symbols", target),
        ]

    if target == "apk" and config.get("build", "split_per_abi"):
        args.append("--split-per-abi")

    args += list(config.get("build", "extra_args") or [])
    return args


def clean(config):
    step("flutter clean")
    shell.run(["flutter", "clean"], cwd=config.root)
    step("flutter pub get")
    shell.run(["flutter", "pub", "get"], cwd=config.root)


def build(config, target):
    banner("build " + target)
    args = _flutter_args(config, target)
    shell.run(args, cwd=config.root)


def _find(config, patterns):
    found = []
    for pattern in patterns:
        found += glob.glob(os.path.join(config.root, pattern))
    return sorted(set(found))


def bundle_artifacts(config):
    flavor = config.get("build", "flavor")
    if flavor:
        return _find(config, ["build/app/outputs/bundle/{0}Release/*.aab".format(flavor)])
    return _find(config, ["build/app/outputs/bundle/release/*.aab"])


def apk_artifacts(config):
    return _find(config, ["build/app/outputs/flutter-apk/*-release.apk"])


def _sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _zip_directory(source, destination):
    if not os.path.isdir(source):
        return None
    entries = []
    for base, _, files in os.walk(source):
        for name in files:
            entries.append(os.path.join(base, name))
    if not entries:
        return None
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in entries:
            archive.write(path, os.path.relpath(path, source))
    return destination


def _native_symbols(config, destination):
    roots = _find(
        config,
        [
            "build/app/intermediates/merged_native_libs/release/*/lib",
            "build/app/intermediates/merged_native_libs/release/out/lib",
            "build/app/intermediates/stripped_native_libs/release/*/lib",
        ],
    )
    for root in roots:
        if _zip_directory(root, destination):
            return destination
    return None


def collect(config, targets, signature=None):
    banner("collect artifacts")

    version = config.pubspec["version"]
    out = os.path.join(config.output_dir, version.replace("+", "-"))
    os.makedirs(out, exist_ok=True)

    collected = []

    if "appbundle" in targets:
        bundles = bundle_artifacts(config)
        if not bundles:
            raise ReleaseError("no .aab was produced under build/app/outputs/bundle")
        for path in bundles:
            collected.append(_copy(path, out))

    if "apk" in targets:
        for path in apk_artifacts(config):
            collected.append(_copy(path, out))

    dart_symbols = os.path.join(config.root, "build", "symbols")
    archive = _zip_directory(dart_symbols, os.path.join(out, "dart-debug-symbols.zip"))
    if archive:
        collected.append(archive)
        info("dart symbols archived, use `flutter symbolize` on obfuscated stack traces")

    native = _native_symbols(config, os.path.join(out, "native-debug-symbols.zip"))
    if native:
        collected.append(native)
        info("upload native-debug-symbols.zip in Play Console -> App bundle explorer")

    notes = _copy_release_notes(config, out)
    collected += notes

    lines = []
    for path in collected:
        if path.endswith(".txt"):
            continue
        lines.append("{0}  {1}".format(_sha256(path), os.path.basename(path)))
    sums = os.path.join(out, "SHA256SUMS.txt")
    with open(sums, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")

    metadata = {
        "app": config.pubspec["name"],
        "applicationId": config.application_id,
        "version": version,
        "versionName": config.pubspec["version_name"],
        "versionCode": config.pubspec["build_number"],
        "builtAt": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "signingCertificateSha256": signature,
        "artifacts": [os.path.basename(path) for path in collected],
    }
    with open(os.path.join(out, "release.json"), "w", encoding="utf-8", newline="\n") as handle:
        json.dump(metadata, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    _prune(config)

    ok("artifacts in " + out)
    for path in collected:
        size = os.path.getsize(path) / (1024.0 * 1024.0)
        info("{0:<40} {1:>8.1f} MB".format(os.path.basename(path), size))
    return out


def _copy(path, out):
    destination = os.path.join(out, os.path.basename(path))
    shutil.copy2(path, destination)
    return destination


def _copy_release_notes(config, out):
    directory = os.path.join(config.store_dir, "release-notes")
    if not os.path.isdir(directory):
        return []
    prefix = config.pubspec["version_name"] + "-"
    copied = []
    for name in sorted(os.listdir(directory)):
        if name.startswith(prefix) and name.endswith(".txt"):
            copied.append(_copy(os.path.join(directory, name), out))
    return copied


def _prune(config):
    keep = config.get("output", "keep_versions") or 0
    if keep <= 0:
        return
    root = config.output_dir
    if not os.path.isdir(root):
        return
    entries = [
        os.path.join(root, name)
        for name in os.listdir(root)
        if os.path.isdir(os.path.join(root, name))
    ]
    entries.sort(key=os.path.getmtime, reverse=True)
    for stale in entries[keep:]:
        shutil.rmtree(stale, ignore_errors=True)


def verify(config, targets):
    banner("verify signing")
    signature = None
    artifacts = []
    if "appbundle" in targets:
        artifacts += bundle_artifacts(config)
    if "apk" in targets:
        artifacts += apk_artifacts(config)

    for path in artifacts:
        info(os.path.basename(path))
        found = keystore.assert_not_debug_signed(path)
        signature = signature or found

    if signature:
        ok("release artifacts are signed with your upload key")
    else:
        warn("could not confirm the signing certificate")
    return signature
