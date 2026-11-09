# Data Sources

This project **hosts nothing itself.** Every file the installers download comes from an
official upstream source, listed below and grouped by what it is. After the one-time download
the whole library runs 100% offline.

This page is the human-readable companion to
[`.github/scripts/check-links.sh`](.github/scripts/check-links.sh), the machine-checked list CI
runs weekly to catch a provider moving a path before users do. The README
[Trust & verification](README.md#-trust--verification) and [License](README.md#license) tables
summarise the same sources at a higher level.

Some sources are **index-driven**: the exact file name changes over time (a new map edition, a
new engine build), so the installer reads an index first and then fetches by name. For those we
list the **stable base URL** and how the name is resolved, rather than a URL that would go stale.

Pieces marked **(opt-in)** are only downloaded when you pass the matching flag or pick them in
the selector; everything else is part of a normal install.

---

## 1. Offline AI (engine + models)

| What | Source | License |
|---|---|---|
| **AI engine — llama.cpp** | `https://github.com/ggml-org/llama.cpp` — release builds resolved from `https://api.github.com/repos/ggml-org/llama.cpp/releases`, then fetched as `https://github.com/ggml-org/llama.cpp/releases/download/<tag>/llama-<tag>-bin-<platform>.<ext>` (`.zip` on Windows, `.tar.gz` on macOS/Linux) | MIT |
| **Chat model — Llama 3.2 3B Instruct (GGUF)** | `https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF` | Llama 3.2 Community License |
| **Chat model — Llama 3.1 8B Instruct (GGUF)** *(default; skip with `--skip-models` or `--lite`)* | `https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF` | Llama 3.1 Community License |
| **Chat model — Qwen2.5 7B Instruct (GGUF)** *(default; skip with `--skip-models` or `--lite`)* | `https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF` | Apache-2.0 |
| **Translator model — Qwen3 4B Instruct (GGUF)** *(opt-in: `--translate`)* | `https://huggingface.co/bartowski/Qwen_Qwen3-4B-Instruct-2507-GGUF` | Apache-2.0 |
| **Document Q&A app — GPT4All** *(default; skipped by `--lite`)* | `https://github.com/nomic-ai/gpt4all` — installer resolved from the repo's GitHub releases | MIT |

> Model files are fetched from each Hugging Face repo as `.../resolve/main/<file>.gguf`.

---

## 2. Encyclopedia & reference archives (Kiwix ZIM)

All ZIMs come from the Kiwix download mirror, `https://download.kiwix.org/`. The installer lists
the directory and picks the newest matching `.zim`, so file names (which carry a date) are
resolved at install time.

| What | Source (directory) | License |
|---|---|---|
| **Kiwix desktop reader** | `https://download.kiwix.org/release/kiwix-desktop/` | GPL-3.0 |
| **Wikipedia** (full, no images) | `https://download.kiwix.org/zim/wikipedia/` | CC BY-SA |
| **iFixit** repair archive | `https://download.kiwix.org/zim/ifixit/` | CC BY-NC-SA |
| **WikiMed** medical Wikipedia | `https://download.kiwix.org/zim/other/` | CC BY-SA |
| **Appropedia** DIY/sustainability | `https://download.kiwix.org/zim/other/` | CC BY-SA |
| **Khan Academy** *(opt-in: `--education`)* | `https://download.kiwix.org/zim/other/` | CC BY-NC-SA |
| **Wikivoyage** *(opt-in: `--extra-zims`)* | `https://download.kiwix.org/zim/wikivoyage/` | CC BY-SA |
| **Wikibooks** *(opt-in: `--extra-zims`)* | `https://download.kiwix.org/zim/wikibooks/` | CC BY-SA |

---

## 3. Maps

| What | Source | License |
|---|---|---|
| **OsmAnd map files** (your region; default US) | Index: `https://download.osmand.net/get_indexes` → files `https://download.osmand.net/download.php?standard=yes&file=<name>.obf.zip` | Map data ODbL-1.0 (OpenStreetMap); OsmAnd code GPL-3.0 |
| **OsmAndMapCreator desktop viewer** | `https://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip` | GPL-3.0 (code); artwork CC BY-NC-ND 4.0 |
| **Portable Java runtime** (Eclipse Temurin 21, for the desktop viewer) | `https://api.adoptium.net/v3/binary/latest/21/ga/<os>/<arch>/jre/hotspot/normal/eclipse` (linux x64/aarch64, mac x64/aarch64, windows x64) | GPL-2.0 WITH Classpath-exception |

### Browser maps *(opt-in: `--browser-maps` / `-BrowserMaps`)*

| What | Source | License |
|---|---|---|
| **US state map tiles (PMTiles) + style** — Project NOMAD | List: `https://api.github.com/repos/Crosstalk-Solutions/project-nomad-maps/contents/pmtiles`; assets `https://github.com/Crosstalk-Solutions/project-nomad-maps/raw/refs/heads/master/...` | MIT (tooling); map data ODbL-1.0 via Protomaps basemaps |
| **MapLibre GL JS** (viewer) | `https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js` + `...maplibre-gl.css` | BSD-3-Clause |
| **pmtiles.js** (tile reader) | `https://unpkg.com/pmtiles@4.4.0/dist/pmtiles.js` | BSD-3-Clause |
| **Caddy** (local web server) | `https://github.com/caddyserver/caddy` — asset resolved from `https://api.github.com/repos/caddyserver/caddy/releases/latest` | Apache-2.0 |

---

## 4. Field manuals & public-domain books (PDF)

Downloaded from the Internet Archive, `https://archive.org/` — the installer reads
`https://archive.org/metadata/<item>` for each item, then fetches the PDF from
`https://archive.org/download/<item>/...`. Unless noted, these are **US Government works (public
domain)** or **out-of-copyright** books. Two Army manuals are *not* plain public-release works, and
are marked ⸸ below — see the [README License note](README.md#license).

| Title | Item |
|---|---|
| FM 21-76 US Army Survival Manual | `https://archive.org/metadata/fm-21-76-us-army-survival-manual` |
| FM 3-05.70 Survival (2002) ⸸ *distribution-restricted ("U.S. Government agencies and their contractors only")* | `https://archive.org/metadata/fm-3-05.70-survival-2002` |
| 105-Page Survival Field Manual | `https://archive.org/metadata/105-page-survival-field-manual` |
| Survival and First Aid for Soldiers ⸸ *contains American Heart Association copyrighted material* | `https://archive.org/metadata/Survival-FirstAidForSoldiers-AFieldManual` |
| FM 4-25.11 First Aid | `https://archive.org/metadata/UsArmyFirstAidManualFm4-25.11` |
| FM 3-25.26 Map Reading and Land Navigation | `https://archive.org/metadata/FM3-25x26` |
| FM 31-70 Basic Cold Weather Manual (1968) | `https://archive.org/metadata/fm-31-70-basic-cold-weather-manual-1968` |
| FM 90-3 Desert Operations (1993) | `https://archive.org/metadata/fm-90-3-desert-operations-1993` |
| FM 21-10 / MCRP 4-11.1D Field Hygiene and Sanitation | `https://archive.org/metadata/FM2110MCRP411.1DFieldHygieneAndSanitation` |
| FM 5-426 Carpentry (1995) | `https://archive.org/metadata/fm-5-426-carpentry-1995` |
| FM 5-428 Concrete and Masonry | `https://archive.org/metadata/armyfm5428concreteandmasonry` |
| FM 5-125 Army Guide to Rigging | `https://archive.org/metadata/u-s-army-guide-to-rigging` |
| TM 5-295 (US Army technical manual) | `https://archive.org/metadata/TM5-295` |
| TM 9-237 Welding Theory and Application | `https://archive.org/metadata/TM9-237` |
| TM 9-243 Use and Care of Hand Tools (1983) | `https://archive.org/metadata/use-and-care-of-hand-tools-and-measuring-tools-1983` |
| TM 9-8000 Principles of Automotive Vehicles (1985) | `https://archive.org/metadata/tm-9-8000-principles-of-automotive-vehicles-1985` |
| TM 10-412 Armed Forces Recipe Service (2003) | `https://archive.org/metadata/tm-10-412-armed-forces-recipe-service-2003` |
| FEMA "Are You Ready?" emergency handbook | `https://archive.org/metadata/FemaEmergencyHandbook-areYouReady` |
| Knots, Splices and Rope Work (Verrill) | `https://archive.org/metadata/knotssplicesrope00verr` |
| Canning, Freezing, Storing Garden Produce (USDA AIB 410) | `https://archive.org/metadata/canningfreezings00unit` |
| Hunting with the Bow and Arrow (Pope) | `https://archive.org/metadata/hunting-with-the-bow-and-arrow` |
| The Book of Camping and Woodcraft (Kephart 1910) | `https://archive.org/metadata/bookofcampingwoo01keph` |
| Deadfalls and Snares (Harding 1907) | `https://archive.org/metadata/deadfalls-and-snares-by-a.-r.-harding-1907` |
| Bait Angling for Common Fishes (Rhead 1907) | `https://archive.org/metadata/baitanglingforco00rhearich` |
| The Boy Mechanic | `https://archive.org/metadata/boymechanicthing01unse` |
| Practical Blacksmithing (1888) | `https://archive.org/metadata/practicalblacksm00rich` |
| Elements of Machine Work (1910) | `https://archive.org/metadata/textbookofelemen00smitrich` |
| Productive Vegetable Growing (Lloyd 1918) | `https://archive.org/metadata/productiveveget00lloy` · PDF `https://archive.org/download/productiveveget00lloy/productiveveget00lloy.pdf` |
| Productive Poultry Husbandry (Lewis 1913) | `https://archive.org/metadata/productivepoult02lewigoog` |
| Langstroth on the Hive and the Honey-Bee (1904) | `https://archive.org/metadata/cu31924003227729` · PDF `https://archive.org/download/cu31924003227729/cu31924003227729.pdf` |
| King's American Dispensatory, vol. 1 | `https://archive.org/metadata/kingsamericandis01kinguoft` |
| King's American Dispensatory, vol. 2 | `https://archive.org/metadata/kingsamericandis02kinguoft` |
| Culpeper's Complete Herbal (public domain; historical reference only) | `https://archive.org/metadata/53357467.6000.emory.edu` |

> Full per-file hashes and text attributions for the manuals indexed by the document-Q&A reader
> are in [`doc-qa/sources.tsv`](doc-qa/sources.tsv).

---

## 5. Food preservation (USDA / NCHFP)

**USDA Complete Guide to Home Canning** (AIB 539, 2015 revision; US-government work, public
domain), hosted by the USDA-funded National Center for Home Food Preservation at
`https://nchfp.uga.edu/`:

- `https://nchfp.uga.edu/papers/guide/INTRO_HomeCanrev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE01_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE02_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE03_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE04_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE05_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE06_HomeCan_rev0715.pdf`
- `https://nchfp.uga.edu/papers/guide/GUIDE07_HomeCan_rev0715.pdf`

---

## 6. Medical & health references

| What | Source | License / terms |
|---|---|---|
| **WHO — Managing Complications in Pregnancy and Childbirth (2017)** | `https://iris.who.int/server/api/core/bitstreams/3bda1306-da5d-487d-b2ad-aff995112a7a/content` | CC BY-NC-SA 3.0 IGO |
| **WHO — Recommendations on Maternal Health (2025)** | `https://iris.who.int/server/api/core/bitstreams/12fdb499-733d-4614-aafc-88dcbbb3c829/content` | CC BY-NC-SA 3.0 IGO |
| **A Practical Guide to Prolonged Casualty Care** (USUHS-HJF 2025) | `https://www.usuhs.edu/sites/default/files/2025-09/Layperson%27s_Guide_to_Prolonged_Casualty_Care_090825_ACC.pdf` | CC BY-NC-SA 4.0 |
| **EPA — Emergency Disinfection of Drinking Water (2017)** | `https://www.epa.gov/sites/default/files/2017-09/documents/emergency_disinfection_of_drinking_water_sept2017.pdf` | US-government work (public domain) |
| **Where There Is No Doctor** (Hesperian) | `https://archive.org/metadata/where-there-is-no-doctor` | Hesperian — non-commercial (copies free or at cost, not for profit); see the original permissions page |
| **Where There Is No Dentist** (Hesperian) | `https://archive.org/metadata/where-there-is-no-dentist-web-full-book` | Hesperian — non-commercial (copies free or at cost, not for profit); see the original permissions page |
| **Emergency Childbirth** (US Office of Civil Defense / Public Health Service) | `https://www.gutenberg.org/cache/epub/26923/pg26923-images.html` | US-government work (public domain); Project Gutenberg e-text |
| **MedlinePlus** health topics *(opt-in: `--medlineplus`)* | `https://medlineplus.gov/xml.html` → `https://medlineplus.gov/xml/<file>` | Public domain (US National Library of Medicine) |

Redistribution terms for the noncommercial WHO/USUHS/Hesperian items are restated in
[`docs/Medical-READ-ME-FIRST.md`](docs/Medical-READ-ME-FIRST.md).

---

## 7. Phone apps (APK)

| What | Source | License |
|---|---|---|
| **OsmAnd~** (Android offline maps) | List: `https://f-droid.org/api/v1/packages/net.osmand.plus` → `https://f-droid.org/repo/net.osmand.plus_<versionCode>.apk` | GPL-3.0 |
| **Kiwix Android** (ZIM reader) | `https://github.com/kiwix/kiwix-android` — APK resolved from `https://api.github.com/repos/kiwix/kiwix-android/releases/latest` | GPL-3.0 |

---

## 8. Education (optional)

| What | Source | License |
|---|---|---|
| **Khan Academy** archive *(opt-in: `--education`)* | `https://download.kiwix.org/zim/other/` (Kiwix ZIM) | CC BY-NC-SA |
| **Kolibri** learning app *(opt-in: `--kolibri`)* | `https://github.com/learningequality/kolibri` — installer resolved from the repo's GitHub releases | MIT |

---

## 9. The project's own repo files

During an install the scripts also pull guides, the browser-map viewer and small helper files
from **this repository**, pinned to the commit `main` is on at the start of the run (so a `main`
that moves mid-download can't change what you get):

- `https://raw.githubusercontent.com/elhajahmadj/offline-emergency-library/<commit>/...`
- `https://api.github.com/repos/elhajahmadj/offline-emergency-library/commits/main` (to resolve that commit)

These are this project's own MIT-licensed files, not a third-party data source.

---

_Keep this file in sync with `.github/scripts/check-links.sh` and the installers when a source
is added or changed._
