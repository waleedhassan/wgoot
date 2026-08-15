# store/play/landing — the app's web page

A self-contained landing page for **وَقُوتُ الصَّلاة** (`apps.waleed.sunnah.wgoot`).
Arabic first with an English toggle, light and dark, no CDN and no external
request of any kind.

```
landing/
  index.html            the page
  privacy-policy.html   copy of ../policy/privacy-policy.html (see below)
  assets/
    icon-512.png        header and favicon
    feature.png         og:image
    screens/*.png       six phone captures from ../graphics/screenshots/phone
    fonts/              Amiri + IBM Plex Sans Arabic, the app's own faces
```

Open `index.html` in a browser to preview — there is nothing to build.

## Deploying

The whole folder is the deploy unit; upload it to any static host. For GitHub
Pages from this repo (Settings → Pages → `master` / `/docs`):

```bash
rm -rf docs && cp -r store/play/landing docs
```

The page lands at `https://<user>.github.io/wgoot/`, and the privacy policy
Play asks for at `https://<user>.github.io/wgoot/privacy-policy.html`. Put that
second URL in `policy/app-content.md` and in the Console.

## The privacy policy copy

`../policy/privacy-policy.html` is the source of truth. `landing/privacy-policy.html`
is a copy so the folder deploys as one unit and the footer link resolves.
Refresh it whenever the policy changes:

```bash
cp store/play/policy/privacy-policy.html store/play/landing/privacy-policy.html
```

## Editing the copy

The text is duplicated per language: every translatable node appears twice, as
`lang="ar"` and `lang="en"` siblings, and CSS hides the one that does not match
`<html data-lang>`. Edit both, or the page silently loses a language.

The wording is kept in step with `../listing/ar.md` and `../listing/en-US.md`.
When the store listing changes, change it here too — Play reviewers do read the
website URL.

## Fonts

Amiri and IBM Plex Sans Arabic are copied from `assets/fonts/` in the repo root
and used under the SIL Open Font License 1.1; the licence texts ship in
`assets/fonts/` here as well.
