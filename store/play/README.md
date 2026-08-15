# store/play — everything Google Play asks for

Every field, answer and asset the Play Console will demand for
**وَقُوتُ الصَّلاة** (`apps.waleed.sunnah.wgoot`), written out so that publishing
is copy-and-paste rather than research.

Start at [`release-process.md`](release-process.md).

```
store/play/
  release-process.md      step by step, from zero to a live listing
  checklist.md            tick-list for launch day
  listing/
    ar.md                 title, short and full description — Arabic (default)
    en-US.md              the same in English
  release-notes/
    1.0.0-ar.txt          "what's new", 500 characters max
    1.0.0-en-US.txt
  policy/
    privacy-policy.html   finished bilingual page, publish it at a public URL
    data-safety.md        the Data safety form, answered
    content-rating.md     the IARC questionnaire, answered
    app-content.md        every other App content declaration, answered
  graphics/
    icon-512.png          generated
    feature-graphic-1024x500.png
    screenshots/          raw captures and processed output
    README.md             what Play requires of each asset
```

## Where each file is used in Play Console

| Console location | File |
| --- | --- |
| Grow → Store presence → Main store listing | `listing/ar.md`, `listing/en-US.md`, `graphics/` |
| Release → Production → release notes | `release-notes/<version>-<locale>.txt` |
| Policy → App content → Privacy policy | the URL you publish `policy/privacy-policy.html` at |
| Policy → App content → Data safety | `policy/data-safety.md` |
| Policy → App content → Content ratings | `policy/content-rating.md` |
| Policy → App content → everything else | `policy/app-content.md` |

## The listing files are machine-checked

`listing/*.md` are not free-form notes. `store/tool/release.py` parses the
`## title`, `## short_description` and `## full_description` headings and fails
the release if any section is missing, over Play's character limit, or still
contains `TODO`. Keep the headings; edit the text under them.

```bash
python store/tool/release.py listing
```

prints the character counts and writes paste-ready `.txt` files into
`build/play/<version>/listing/`.

## What is deliberately left blank

Three values depend on decisions only you can make, and appear as parenthesised
placeholders in the policy documents:

- **Privacy policy URL** — where you host the page. Two options are in
  `release-process.md` §2.
- **Public contact email** — shown on the listing to anyone.
- **Website** — optional.

Everything else is filled in.

## Keeping it honest

The Data safety declaration says the app collects nothing. That is true of the
code as it stands: no `INTERNET` permission in the release manifest, no HTTP
client anywhere in `lib/`, no analytics or ads dependency, no location
permission. It stops being true the moment any of those change, and a false
declaration is grounds for suspension.

`store/tool/release.toml` pins the exact permission list, so preflight fails if
a new one appears. When that happens, update `policy/data-safety.md` in the same
commit.
