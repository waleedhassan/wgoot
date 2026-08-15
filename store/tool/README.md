# Flutter → Play Store release tooling

One command takes a Flutter app from source to a signed App Bundle that is ready
to upload, and refuses to produce one that Play would reject.

```bash
python store/tool/release.py
```

Nothing here is specific to this app. Copy `release.py`, `release.toml`,
`release.ps1`, `release.sh`, `requirements.txt` and `flutter_play/` into any
Flutter project, edit `release.toml`, and it works there.

---

## Install

Python 3.11 or newer (it reads `release.toml` with the standard-library
`tomllib`), plus:

```bash
pip install -r store/tool/requirements.txt
```

| Package | Used for |
| --- | --- |
| Pillow | store icon, feature graphic, screenshot processing |
| arabic-reshaper | correct Arabic letter joining in generated graphics |
| python-bidi | right-to-left ordering in generated graphics |

Only the `graphics` and `screenshots` commands need these. Building and
preflight run on a bare Python.

You also need `flutter` on PATH, `keytool` from any JDK, and `adb` if you want
screenshot capture.

## Run it

```bash
python store/tool/release.py
```

On Windows, `store\tool\release.ps1` finds Python for you. On macOS and Linux,
`store/tool/release.sh` does the same.

The default pipeline:

1. Offer to create an upload keystore if none exists
2. Apply a version bump, if one was asked for
3. Generate store graphics if they are missing
4. Run every static preflight check — **stops here if any fail**
5. `flutter clean` and `flutter pub get`
6. `flutter analyze` and `flutter test` — **stops here if either fails**
7. `flutter build appbundle --release`
8. Verify the signing certificate and refuse debug-signed output
9. Collect artifacts, symbols, release notes and checksums into `build/play/<version>/`
10. Export paste-ready listing text

## Commands

| Command | What it does |
| --- | --- |
| `release.py` | The full pipeline above |
| `release.py preflight` | Checks only. `--fast` skips analyze and tests |
| `release.py keystore` | Create the upload keystore and `android/key.properties` |
| `release.py fingerprints` | Print the upload key's SHA-1 and SHA-256 |
| `release.py graphics` | Generate `icon-512.png` and the feature graphic |
| `release.py screenshots --capture` | Grab screenshots over adb, then normalise them |
| `release.py listing` | Export listing text and check character limits |
| `release.py build` | Build, verify and collect, skipping the checks |
| `release.py version` | Show the version. `--bump build` to raise it |

## Flags

| Flag | Effect |
| --- | --- |
| `--bump build\|patch\|minor\|major` | Raise the version in `pubspec.yaml` |
| `--set 1.2.0+7` | Set an exact version |
| `--apk` | Also build a release APK alongside the bundle |
| `--apk-only` | Build only an APK |
| `--no-clean` | Skip `flutter clean` and `pub get` |
| `--skip-checks` | Skip analyze and tests |
| `--force` | Build even though checks failed |
| `--yes` | Never prompt — for CI |
| `--config PATH` | Use a different `release.toml` |
| `--project PATH` | Point at a different Flutter project |

Exit codes: `0` success, `1` error, `2` checks failed, `130` interrupted.

## What preflight actually checks

**Toolchain** — `flutter` and `keytool` on PATH.

**Version** — `pubspec.yaml` parses as `MAJOR.MINOR.PATCH+BUILD`, and the build
number is at least 1. Play tracks the build number as versionCode and refuses an
upload that does not raise it.

**Application id** — present, reverse-domain shaped, and not a template
placeholder like `com.example.*`. Play binds this id to the listing permanently.

**Signing** — a release `signingConfig` is wired in Gradle,
`android/key.properties` points at a keystore that exists, and neither the
properties file nor any `.jks` is tracked by git.

**Manifest** — `android:label` and `android:icon` set, `android:debuggable` not
forced on, a LAUNCHER activity declared, and every permission listed. Anything
in Play's restricted set is flagged with what the declaration will demand.
`INTERNET` in the release manifest is called out, because for an offline app it
belongs in `src/debug/` and its presence quietly contradicts a "no data
collected" Data safety form.

**SDK levels** — targetSdk meets Play's current minimum.

**Icons** — a launcher icon at every density plus an adaptive icon.

**Listing** — every locale in `release.toml` has a file with `## title`,
`## short_description` and `## full_description`, each within Play's 30 / 80 /
4000 character limits, with no `TODO` left in.

**Release notes** — a file per locale for the current version, ≤500 characters.

**Policy** — the privacy policy, Data safety, content rating and app content
documents all exist.

**Graphics** — store icon, feature graphic, and at least 2 phone screenshots.

The unexpected-permission check is the one worth keeping honest. Set
`checks.allowed_permissions` in `release.toml` to exactly what the app declares
today; preflight then fails the moment a dependency adds a new one, which is how
a Data safety declaration silently becomes a lie.

## Configuration

Everything lives in `release.toml`. The interesting parts:

```toml
[build]
appbundle = true
obfuscate = true          # --obfuscate --split-debug-info
flavor = ""
dart_defines = []

[checks]
require_release_signing = true
allowed_permissions = [...]   # empty list disables the check

[store]
dir = "store/play"
listing_locales = ["ar", "en-US"]

[graphics]
title = "..."             # defaults to the pubspec name
font = "assets/fonts/..."
icon_source = "assets/icon/app_icon.png"
```

Missing keys fall back to the defaults in `flutter_play/config.py`. With no
`release.toml` at all, the tool still runs on defaults.

## Output

```
build/play/1.0.0-1/
  app-release.aab
  dart-debug-symbols.zip      # for `flutter symbolize`
  native-debug-symbols.zip    # upload in Play's App bundle explorer
  1.0.0-ar.txt                # release notes, copied for convenience
  listing/ar.title.txt        # paste-ready listing fields
  SHA256SUMS.txt
  release.json                # version, applicationId, signing SHA-256, timestamp
```

Old version folders are pruned to `output.keep_versions`.

## Signing safety

The tool never writes a password anywhere except `android/key.properties`, which
Gradle needs and which it verifies is git-ignored. Passwords reach `keytool`
through environment variables rather than the command line, so they do not show
up in the process list.

`release.py keystore` is the only interactive step. It prompts for the password
directly — the password is never passed as an argument and never logged.

After the build, the signing certificate of every artifact is read back with
`keytool -printcert`. If the owner is `CN=Android Debug`, the pipeline stops:
that bundle would be rejected by Play, and catching it here is cheaper than
finding out after an upload.

## Using it in CI

```bash
python store/tool/release.py --yes --bump build --skip-checks
```

`--yes` suppresses every prompt. Provide `android/key.properties` and the
keystore from your CI secret store — never from the repository.

## Adding it to another Flutter project

```bash
cp -r store/tool /path/to/other-app/store/tool
cd /path/to/other-app
$EDITOR store/tool/release.toml     # colours, title, locales, permissions
python store/tool/release.py preflight --fast
```

Then create `store/play/listing/<locale>.md` files with the three `##` sections.
Preflight tells you exactly what is still missing.
