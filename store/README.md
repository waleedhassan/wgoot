# store — distribution

Two halves:

- **[`play/`](play/README.md)** — everything Google Play asks for about *this*
  app: listing text in Arabic and English, release notes, the privacy policy,
  and every App content declaration answered in advance.
- **[`tool/`](tool/README.md)** — the scripts that take *any* Flutter app from
  source to an upload-ready App Bundle in one command.

## First time

```bash
pip install -r store/tool/requirements.txt
```

```bash
python store/tool/release.py keystore
```

Then follow [`play/release-process.md`](play/release-process.md).

## Every release

```bash
python store/tool/release.py --bump build
```

Checks, builds, verifies the signature, and drops everything you need to upload
into `build/play/<version>/`.

## Where to look when something is unclear

| Question | File |
| --- | --- |
| How do I publish this app, start to finish? | [`play/release-process.md`](play/release-process.md) |
| What still needs doing before launch? | [`play/checklist.md`](play/checklist.md) |
| What do I answer in the Data safety form? | [`play/policy/data-safety.md`](play/policy/data-safety.md) |
| What do I answer everywhere else in App content? | [`play/policy/app-content.md`](play/policy/app-content.md) |
| What text goes on the listing? | [`play/listing/ar.md`](play/listing/ar.md) |
| What does the build tool do and how do I configure it? | [`tool/README.md`](tool/README.md) |
| How do I reuse this for a different Flutter app? | [`tool/README.md`](tool/README.md), last section |
