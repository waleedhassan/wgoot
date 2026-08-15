# Publishing وقوت الصلاة to Google Play

Written for the first release. After that, only "Every release after the first"
at the bottom applies.

---

## 0. What you need before you start

| Thing | Notes |
| --- | --- |
| Google Play Developer account | One-off 25 USD. Personal accounts opened after Nov 2023 need 12 testers running a closed test for 14 days before production access. |
| A JDK | For `keytool`. Android Studio ships one under `jbr/bin`. |
| Python 3.11+ | For the tooling in `store/tool/`. |
| A public URL for the privacy policy | Step 2 below. |

Install the tooling's Python dependencies once:

```bash
pip install -r store/tool/requirements.txt
```

---

## 1. Create the upload keystore

This is the single irreversible step. The key you make here signs every future
update; lose it and you can never update this listing again.

```bash
python store/tool/release.py keystore
```

It prompts for a password, generates `android/upload-keystore.jks`, writes
`android/key.properties`, and confirms both are git-ignored.

Then back it up — both the `.jks` file and the password — somewhere that
survives this machine dying. A password manager plus an offline copy is the
usual answer. Do not put either in the repository.

To see the fingerprints later:

```bash
python store/tool/release.py fingerprints
```

> **Play App Signing.** Play re-signs your app with a key Google holds, and your
> upload key only proves the upload came from you. It is enabled by default for
> new apps and you should keep it: if you ever lose the upload key, Google can
> reset it, which is impossible with the app signing key. Accept the terms when
> Console offers them.

---

## 2. Publish the privacy policy at a public URL

Play requires a URL that anyone can open without logging in.
`store/play/policy/privacy-policy.html` is a finished, self-contained page —
Arabic and English, light and dark, no external assets.

**Option A — GitHub Pages, from this repo:**

```bash
mkdir -p docs && cp store/play/policy/privacy-policy.html docs/index.html
```

Commit, push, then in GitHub → Settings → Pages set the source to the `master`
branch and the `/docs` folder. The page lands at
`https://<user>.github.io/wgoot/`.

**Option B — anywhere else.** Any static host works. The file has no
dependencies; upload it as-is.

Whichever you pick, open the URL in a private window to confirm it loads, then
put it in `app-content.md` and in the Console.

---

## 3. Generate the store graphics

```bash
python store/tool/release.py graphics
```

Writes `store/play/graphics/icon-512.png` and
`feature-graphic-1024x500.png`. See [`../graphics/README.md`](../graphics/README.md)
for what Play expects.

## 4. Screenshots — already done

Eight are shipped in `store/play/graphics/screenshots/phone/`, all 1080×2160
and Play-compliant. Six came off a real device, two were rendered from the
widget tree. Nothing to do here unless you want to change them — see
[`../graphics/README.md`](../graphics/README.md) for how to redo either kind.

Note that a raw phone screenshot is 1080×2400, which is 2.22:1 and **over Play's
2:1 limit**. Anything you add later has to be cropped down the same way.

---

## 5. Build the release

```bash
python store/tool/release.py
```

That single command runs the whole pipeline: preflight checks, `flutter clean`,
`pub get`, `analyze`, `test`, the signed App Bundle, a signing verification that
refuses debug-signed output, and artifact collection into
`build/play/<version>/`.

You end up with:

```
build/play/1.0.0-1/
  app-release.aab              <- upload this
  dart-debug-symbols.zip       <- for `flutter symbolize`
  native-debug-symbols.zip     <- upload in App bundle explorer
  1.0.0-ar.txt                 <- release notes, ready to paste
  1.0.0-en-US.txt
  listing/                     <- listing text, ready to paste
  SHA256SUMS.txt
  release.json
```

---

## 6. Create the app in Play Console

Play Console → Create app.

| Field | Value |
| --- | --- |
| App name | وقوت الصلاة — مواقيت وأذان |
| Default language | Arabic (ar) |
| App or game | App |
| Free or paid | Free — this cannot be changed to paid later |
| Declarations | Tick the developer programme policies and US export laws |

## 7. Fill in App content

Work through [`app-content.md`](app-content.md) top to bottom. Every answer you
need is already written out, including Data safety and the content rating.

## 8. Set up the store listing

Play Console → Grow → Store presence → Main store listing.

Paste from `build/play/<version>/listing/` (or from
[`../listing/ar.md`](../listing/ar.md) and [`en-US.md`](../listing/en-US.md)),
then upload the graphics from `store/play/graphics/`.

Add the English listing as a second language under Store listings → Manage
translations → Add your own translation text.

## 9. Closed testing

New personal developer accounts must run a closed test with at least 12 testers
opted in for 14 continuous days before production unlocks. Start this early — it
is a wall clock requirement, not a work requirement.

Play Console → Testing → Closed testing → Create release, upload the `.aab`,
paste the release notes, add testers by email list or Google Group.

## 10. Production

Play Console → Production → Create new release. Upload the same `.aab` (or a
newer build), paste the release notes, set the rollout percentage, and submit.

First review typically takes a few days and can take longer.

---

## Every release after the first

```bash
python store/tool/release.py --bump build
```

Then:

1. Write `store/play/release-notes/<version>-ar.txt` and `-en-US.txt`,
   500 characters maximum each.
2. Upload the new `.aab` to a new release in Console.
3. Update Data safety only if what the app collects actually changed.

`--bump build` increments only the versionCode, which is what Play tracks.
Use `--bump patch`, `--bump minor` or `--bump major` when the user-visible
version should move too.

---

## Things that will get the release rejected

- An `.aab` signed with debug keys. The pipeline checks for this and stops.
- A versionCode that is not higher than the last uploaded one.
- A privacy policy URL that 404s, redirects to a login, or does not mention this app.
- A Data safety form that contradicts the app's actual behaviour.
- Screenshots that show a device frame, an alien status bar, or marketing text
  covering the app itself.
- A listing that implies official endorsement by a government or religious body.
- Keywords stuffed into the title or short description.
