# Data safety — answers for Play Console

**Where:** Play Console → Policy and programmes → App content → Data safety

Everything below was derived from the actual code, not from intent:

- No `INTERNET` permission in `android/app/src/main/AndroidManifest.xml`
  (it exists only in `src/debug/`, which never ships).
- No HTTP client, no `Uri.parse`, no socket use anywhere in `lib/`.
- No analytics, ads, crash reporting or attribution SDK in `pubspec.yaml`.
- No location permission and no geolocation package — the city is picked by hand.
- The only persistence is `shared_preferences`, which writes to the app's
  private storage on the device.

Re-verify with:

```bash
python store/tool/release.py preflight --fast
```

---

## Section 1 — Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |

Play defines "collect" as transmitting data off the device. This app transmits
nothing, so the whole questionnaire collapses to a single No and the remaining
questions in this section are skipped by the Console.

If the Console still shows them, the answers are:

| Question | Answer |
| --- | --- |
| Is all of the user data collected by your app encrypted in transit? | Not applicable — no data is collected |
| Do you provide a way for users to request that their data is deleted? | Not applicable — no data is collected |

## Section 2 — Data types

Leave **every** data type unticked:

- Location — approximate, precise → **No**
- Personal info — name, email, user IDs, address, phone, race, political or
  religious beliefs, sexual orientation, other → **No**
- Financial info → **No**
- Health and fitness → **No**
- Messages → **No**
- Photos and videos → **No**
- Audio files → **No**
- Files and docs → **No**
- Calendar → **No**
- Contacts → **No**
- App activity — interactions, in-app search history, installed apps, other
  user-generated content, other actions → **No**
- Web browsing history → **No**
- App info and performance — crash logs, diagnostics, other → **No**
- Device or other IDs → **No**

> Note the religious-beliefs trap. Choosing a city and a calculation method is a
> religious signal, but the app never sends it anywhere, so it is not collected
> under Play's definition. It stays on the device, and the store listing and the
> privacy policy both say so explicitly.

## Section 3 — Privacy policy

| Field | Value |
| --- | --- |
| Privacy policy URL | *(the public URL you publish `privacy-policy.html` at)* |

The URL must be publicly reachable, must not require a login, and must actually
mention this app. See `store/play/release-process.md` for two ways to host it.

## Section 4 — Advertising ID

| Question | Answer |
| --- | --- |
| Does your app use advertising ID? | **No** |

The app declares no `com.google.android.gms.permission.AD_ID` permission and
bundles no ads SDK.

---

## The resulting store label

Your listing will show:

> **No data shared with third parties**
> **No data collected**
> Data is not encrypted — *not applicable, nothing is transmitted*
> You can request that data be deleted — *not applicable*

## Keeping this true

This declaration is a promise, and a false one is grounds for suspension.
It stops being true the moment anyone adds:

- any analytics, crash reporting or ads package,
- a remote prayer-times or Hijri API,
- a backup or sync feature,
- a "share your settings" or feedback-upload feature.

`store/tool/release.toml` pins the permission list under
`checks.allowed_permissions`, so preflight fails if a new permission appears in
the release manifest. Update this document in the same commit that changes it.
