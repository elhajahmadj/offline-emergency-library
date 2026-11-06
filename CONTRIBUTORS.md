# Contributors

Thanks to everyone who has improved this project. ❤️

**Testing and bug reports count as contributions here** — running the installer on real
hardware and reporting what breaks is just as valuable as code, and it's credited the same
way. Credit for specific fixes is in the [CHANGELOG](CHANGELOG.md) and in the GitHub release
notes.

## People

- **[@elhajahmadj](https://github.com/elhajahmadj)** — creator and maintainer.
- **[@boostedchaos](https://github.com/boostedchaos)** (Kyle Welch) — PR reviewer, and
  macOS/Windows testing plus a lot of fixes/features: `curl … | bash` destination prompt
  (`/dev/tty`), Wikipedia as a Kiwix-readable `nopic` ZIM, the aria2 acceleration idea, AI
  engines for every OS on one drive (PR #9), the default-US-maps region fix (PR #11), the
  iPhone/iPad phone guide (PR #12), opt-in extra Kiwix archives (PR #56), the PR-review
  checklist (PR #61), CI launcher-parity (PR #65), the re-run refresh-by-size fix (PR #60),
  the MedlinePlus CSP-by-hash hardening (PR #97), and the real-hardware diagnosis on #15 that
  the bundled Java map viewer only draws online tiles (blank offline on Windows and macOS).
  More in the [CHANGELOG](CHANGELOG.md).
- **[@xtalax](https://github.com/xtalax)** (Alex Jones) — Linux testing; diagnosed and
  fixed the `download.kiwix.org` → `lb.download.kiwix.org` redirect so Bash lookups
  follow `-L` and all Kiwix archives download.
- **[@EnragedAntelope](https://github.com/EnragedAntelope)** — PR reviewer, and Windows
  testing, bug reports and fixes: the chat-launcher `-cnv` fix for current llama.cpp (PR #13),
  fail-loudly download-error handling (PR #14), the `-Lite`/`--lite` quick-start preset
  (PR #16), the report of the Windows blank-map desktop-viewer limitation
  ([#15](https://github.com/elhajahmadj/offline-emergency-library/issues/15)), the offline
  translator (PR #62), opt-in MedlinePlus health topics (PR #87), the `.gguf` self-check
  against Hugging Face (PR #88), the free-space check (PR #93), and the README restructure
  (PR #95) — among others; see the [CHANGELOG](CHANGELOG.md).
- **[@imsurya26](https://github.com/imsurya26)** — the POWER-AND-DEVICES browser-maps docs
  fix (PR #111) and extending the post-install self-check to cover the desktop map viewer
  and Java runtime (PR #112).
- **[@NachoBusiness17](https://github.com/NachoBusiness17)** — an independent end-to-end
  verification of the full source manifest (26/26 sources live, 72.69 GiB) with per-source
  bytes and dates, plus the capacity and per-source-license notes in
  [#52](https://github.com/elhajahmadj/offline-emergency-library/issues/52).

Want to help? See [CONTRIBUTING](.github/CONTRIBUTING.md) and the open issues —
testers for the macOS/Linux installers are especially welcome.
