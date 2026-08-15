# Play Store launch checklist

Tick down the list. Anything the tooling can verify is marked `[auto]` — run
`python store/tool/release.py preflight` and it checks that line for you.

## One-off setup

- [ ] Google Play Developer account created and verified (25 USD, ID verification)
- [ ] Payment profile completed (needed even for a free app)
- [ ] `pip install -r store/tool/requirements.txt`
- [ ] Upload keystore created — `python store/tool/release.py keystore` `[auto]`
- [ ] Keystore file **and** password backed up outside this machine
- [ ] `android/key.properties` and `*.jks` confirmed git-ignored `[auto]`
- [ ] Play App Signing terms accepted in Console

## The app itself

- [ ] `applicationId` is final — `apps.waleed.sunnah.wgoot`, unchangeable after publish `[auto]`
- [ ] Version in `pubspec.yaml` is correct `[auto]`
- [ ] versionCode is higher than anything already uploaded `[auto]`
- [ ] targetSdk meets Play's current minimum `[auto]`
- [ ] Launcher icons present at every density, adaptive icon defined `[auto]`
- [ ] No `INTERNET` permission in the release manifest `[auto]`
- [ ] No unexpected permissions crept in `[auto]`
- [ ] `flutter analyze` clean `[auto]`
- [ ] `flutter test` passing `[auto]`
- [ ] Tested on a real device, not just the emulator
- [ ] Adhan fires at the right minute after the screen has been off for hours
- [ ] Alerts survive a reboot
- [ ] Home screen widget updates and resizes
- [ ] Arabic RTL layout correct on a small screen and at large font sizes
- [ ] Dark theme checked
- [ ] Back gesture and back button behave

## Store listing

- [ ] `store/play/listing/ar.md` filled in, within limits `[auto]`
- [ ] `store/play/listing/en-US.md` filled in, within limits `[auto]`
- [ ] Release notes for this version, both locales, ≤500 characters `[auto]`
- [x] `icon-512.png` generated — 512×512, 32-bit PNG, opaque `[auto]`
- [x] `feature-graphic-1024x500.png` generated `[auto]`
- [x] 8 phone screenshots, all 1080×2160 at exactly 2:1 `[auto]`
- [x] Screenshots show the real app, no device frames, no covering text
- [x] Status bar and gesture pill cropped out of the device captures
- [ ] App category set to Lifestyle
- [ ] Public contact email set
- [ ] Countries and regions chosen

## Policy and declarations

- [ ] Privacy policy published at a public URL that loads without a login
- [ ] Privacy policy URL entered in Console
- [ ] App access — all functionality available without restrictions
- [ ] Ads — no ads
- [ ] Content rating questionnaire completed, result Everyone / PEGI 3
- [ ] Target audience — 13+, not appealing to children
- [ ] News app — no
- [ ] COVID-19 apps — no
- [ ] Data safety — no data collected, no data shared, no advertising ID
- [ ] Government apps — no
- [ ] Financial features — none
- [ ] Health — no
- [ ] Exact alarm justification ready if Console asks

## Build and upload

- [ ] `python store/tool/release.py` finished with no blocking failures
- [ ] `.aab` verified as signed with the upload key, not debug keys `[auto]`
- [ ] `native-debug-symbols.zip` uploaded in App bundle explorer
- [ ] Release notes pasted for both locales
- [ ] Closed test with 12+ testers running, if the account requires it
- [ ] 14-day closed test window elapsed, if the account requires it
- [ ] Production release created and submitted

## After the release goes live

- [ ] Install from Play on a clean device and confirm it opens
- [ ] Check Android vitals after a few days for ANRs and crashes
- [ ] Watch the reviews for reports of wrong times in specific cities
- [ ] Tag the release in git
- [ ] Keep the `build/play/<version>/` folder — it has the exact artifacts and
      the signing fingerprint for that upload
