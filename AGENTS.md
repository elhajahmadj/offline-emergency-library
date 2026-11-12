# Offline Emergency Library

Portable installers assemble an offline reference library. Read
`.github/CONTRIBUTING.md` and the PR template before changing files.

## Current state
_Last verified: 2026-11-12_

- Status: issue 72 documents the tested chat context limit; issue 102 corrects
  browser-map estimates and uses a conservative space budget; browser-only additions
  preserve existing OsmAnd region metadata (issue 125); issue 75 adds opt-in browser
  translator launchers alongside the terminal translator; issue 63 adds a ready-to-use
  manual Q&A reader (`doc-qa/`) that reuses the bundled llama.cpp server and model (the
  GPT4All database is deliberately not shipped because its stored paths do not survive
  relocation). Issue 160 improves lexical retrieval with frequency scoring and
  topic headings, covered by an offline question set. Issue 107 adds the bundled
  OffRoad desktop viewer, which renders the drive's OBF maps offline on Windows,
  macOS and Linux for any region. Review fixes put Windows's private junction on local
  NTFS so exFAT drives and relocation work, and replace SQLite JDBC on Apple Silicon
  with an ARM64-compatible build (Windows runtime QA; macOS and Linux not tested here).
  Issue 79 adds the phone docs pack: `.github/workflows/phone-pack.yml` builds the
  `sources.tsv` manuals plus phone-useful guides into a zip on the fixed `phone-pack`
  release, linked by a QR code (`web/phone-pack-qr.svg`) and documented in `USE-ON-PHONE`.
  The `phone-pack` release is live: `Offline-Emergency-Phone-Pack.zip` (about 259 MB,
  rebuilt by the workflow whenever its inputs change). The builder routes each
  archive.org PDF through the item's own data nodes first, with the download redirect
  last, so GitHub runners stop timing out on European nodes (#247, #250).
- Front end (issue 66, milestone #139): a static HTML picker site is built and lives under
  `web/` — the picker (`index.html`), landing, About, Documentation, Data Sources and
  Privacy pages. Generated files are rebuilt from their sources and checked in CI:
  `build-catalog-js.sh` (catalog.js from catalog.json), `build-about.sh` (about.html from
  CONTRIBUTORS.md) and `build-web-docs.sh` (the `web/docs/` guide mirror; `build-web-docs.py`, Python 3, maps
  guide links by the installer's `place_doc` lines and turns drive-only links into text). One component
  table (`components.tsv`) is the single source of each download's size, flag, presets,
  license and source link, with a CI license gate, and `SOURCES.md` is generated from it
  (#239, #244, issue 67). Both installers run a guided install when given no flags (#221).
  The live site is the Fly deployment (`sine-nexu.fly.dev`, #218); the GitHub Pages workflow
  is a known gap below.
- Works: aria2 fallback, cancellation and partial-file protection have offline regression checks;
  large-model chat launchers follow the model selection in both installers (issue 168);
  changelog compilation rejects invalid bullet starts and missing numeric PR references,
  with offline fixture regressions in the lint job;
  manual reader launchers have offline per-OS execution checks after relocation;
  an offline CLI regression covers existing and absent OsmAnd folders, selected browser maps and region size estimates;
  Windows browser translation and shutdown passed runtime QA; generated checks cover parity and ownership;
  the manual reader's source pairing (PDF hash to text hash), installer parity and relocation have an
  offline regression check, and text freshness is checked in CI;
  `check-consistency.sh` keeps manual downloads, link checks and guide placement the same
  in both installers; issue templates add the type label and blank issues are off;
  start-up mistakes (a flag with no value, an unknown flag, a region with no maps, an early stop)
  exit 1 with a plain message, and both installers fetch their repo files from the commit main
  was on when the run started (issues 192, 193); `--only` re-hashes only what its pieces wrote,
  with byte parity between the installers checked in CI (issue 195);
  the space estimate is correct under a decimal-comma locale (#245; issue 104 stays open for the Linux and Education/Kolibri paths).
- In progress: the front-end direction beyond the HTML picker — desktop app, then phone
  (issues 66, 84, 139); more public-domain manuals, licenses first (issues 130, 78); and the
  outstanding test rounds for the OffRoad viewer and reader on Linux x64/arm64 and the wider
  CI matrix (issues 108, 159, 117).
- Known gaps: the `Publish picker site` GitHub Pages workflow is manual-dispatch only — Pages
  was never enabled and its workflow token cannot create the site, so the live host is Fly, not
  Pages (issue 252, #259); the Documentation page has dead drive-relative links and external links
  that open inside the iframe (issue 253); the self-check has no browser-maps line and Windows
  `Expand-Archive` does not verify a zip's CRCs (issues 256, 255); nine `docs/*.html` guides
  render literal `**` and split sentences (issue 254); native macOS double-click testing and
  independent Swahili and Somali language review are still outstanding.
- Deep docs: `evaluations/issue-73/README.md` describes the interpreter protocol;
  `evaluations/issue-76/README.md` describes the CPU model comparison;
  `docs/HOW-TO-TRANSLATE.md` describes browser requirements and local chat storage.

## Files PRs must not edit

- `SHA256SUMS.txt`: regenerated by `.github/workflows/sha256sums.yml` after every merge to `main`.
- `CHANGELOG.md`: add a fragment in `changelog.d/` instead (format in `changelog.d/README.md`);
  the maintainer compiles fragments into `CHANGELOG.md` at release time with
  `.github/scripts/compile-changelog.sh`.

## Checks

Repository checks and contribution requirements are maintained in
`.github/CONTRIBUTING.md` and `.github/workflows/ci.yml`.
The evaluation is a separate Windows PowerShell script, not part of installation.
Its invocation, limits, and raw result format are documented next to it.
Windows CI also runs `.github/scripts/check-fetch.ps1` with Windows PowerShell 5.1
to exercise the installer's real downloader against local executable fixtures (plus
`Expand-Zip` refusing a bad-CRC zip: the installer unpacks zips with
`%SystemRoot%\System32\tar.exe`, never plain `tar.exe`, which Git Bash resolves to GNU tar), and
`.github/scripts/check-doc-qa.ps1` for reader source pairing and relocation.
`.github/scripts/check-doc-sources.sh` verifies that published manual text still matches
`sources.tsv`; a changed publisher file must be reviewed, not silently re-hashed. Archive.org timeouts and 5xx are warnings; only a 4xx or changed text fails.
Maintenance notes for the reader live in `doc-qa/README.md`.
`.github/scripts/check-offroad-viewer.sh` verifies the OffRoad launcher links the
prepared OBF folder without copying it, passes the Java 21 compatibility flag, starts
the bundled jar, and applies the ARM64 SQLite package only on Apple Silicon.
`.github/scripts/check-offroad-viewer.ps1` executes the real generated Windows launcher
against stale junctions and relocation with a fake Java, without network access.
`.github/scripts/check-launchers.sh` runs model placement with local download fixtures
and checks generated launcher model references across full, Lite, skipped-model and
translator selections. It runs in the existing lint job on PRs and the weekly schedule.
For the milestone 2 picker (#139), also exercise a fresh non-Lite selection containing
`core`, `gpt4all-repair` and `wikipedia` without `models` on both installers; verify
the large models and their launchers are absent while the core chat remains available.
`.github/scripts/check-consistency.sh` (lint job, offline) fails when a manual download
differs between the installers or is missing from `check-links.sh`, a guide lacks its
`.md` or `.html` half, or the installers place different guides.
`.github/scripts/check-checksums.sh` runs both installers' drive-check sections on one fixture
(full run and `--only`) and requires identical `CHECKSUMS-SHA256.txt` lists; on Windows Git Bash
`sha256sum` writes `*` before each path, so run it on Linux or macOS. A new `--only` piece needs
its paths added to `RH` / `$rh` in both installers.
`.github/scripts/check-selfcheck-browser-maps.sh` runs both installers' browser-maps self-check
block (`# 7. Browser maps`, ending before the guided-command line) on fixture drives and requires
the same PASS/FAIL/WARN line; keep that marker if the self-check is reordered.
`node --test doc-qa/retrieval.test.mjs` checks ranking without inference; the CI
lint job runs it on PRs and the existing weekly schedule.
`.github/scripts/build-phone-pack.py OUT.zip [--from DRIVE]` builds the phone pack and
stops on any PDF whose hash differs from `sources.tsv`, so the release keeps its last good
zip. The QR code encodes a fixed release URL; regenerate it only if the URL changes.
The builder finds each manual's source from the `get_pdf` / `get_pdf_url` lines in
`get-offline-library.sh`; keep those lines' shape unchanged, or update the builder with them.
`DRIVE_ONLY` in the builder lists manuals that must not be hosted in the pack; `TOO_BIG`
lists hostable manuals left out only to keep the pack small.
