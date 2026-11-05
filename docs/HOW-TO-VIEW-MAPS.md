# Offline Maps — How to View Them (PC or Phone)

The `OsmAnd\` folder contains offline maps (`.obf.zip` files) for the **region you chose at
download time** (the default is the **United States**). You can use them **on a computer
(no phone needed)** or **on a phone/tablet**. Browser maps and the phone app work with **no
internet**; the OsmAndMapCreator viewer (Option 1) needs internet on Windows and macOS.
Dependencies for each are bundled or explained below.

---

## Street maps in a web browser — ✅ recommended on a computer (opt-in: `-BrowserMaps` / `--browser-maps`)

Add `-BrowserMaps` (Windows) or `--browser-maps` (macOS/Linux) when you run the installer to also get
**street maps that open in any web browser**, on Windows, macOS or Linux. No app and no Java are needed.

**This is the recommended way to view maps on a computer, especially on Windows** — it renders
reliably in the browser, with no internet. The OsmAndMapCreator desktop viewer below cannot draw the
drive's maps on Windows or macOS ([#15](https://github.com/elhajahmadj/offline-emergency-library/issues/15)).
Browser maps cover the **US** only; for other countries, use an Android phone (Option 2).

1. Open the `Maps-Browser\` folder.
2. **Windows:** double-click `OPEN-MAPS.bat`. **macOS / Linux:** run `bash OPEN-MAPS.sh` in a terminal.
3. Your browser opens at **http://localhost:8097/viewer/**. Zoom with the mouse wheel, or pick a state in
   **Go to a state**. To stop, close the OPEN-MAPS window.

- **US only.** These are the US state maps made by Project NOMAD (Protomaps). With `US` (the default) you get
  all 50 states (~16.5 GB). With `-Region US_texas` you get only Texas. Every drive also gets a low-detail
  world map (~0.2 GB). For other countries, use the OsmAnd maps below.
- **Space:** browser maps come **on top of** the OsmAnd maps, which are always downloaded with them
  (~17.8 GB for the US). A full US drive with `-BrowserMaps` needs about **34 GB for maps**.
- They show streets, towns, parks and water. They cannot plan a route; use OsmAnd for directions.
- Map data © OpenStreetMap contributors (ODbL); maps by [Project NOMAD](https://github.com/Crosstalk-Solutions/project-nomad-maps)
  (MIT) from [Protomaps](https://github.com/protomaps/basemaps); viewer [MapLibre GL JS](https://maplibre.org) (BSD-3);
  local web server [Caddy](https://caddyserver.com) (Apache-2.0).

---

## Choosing your country / region (at download time)

By default the installer downloads **US** maps. To get a different country, region, or
continent, pass `-Region` (Windows) or `--region` (macOS/Linux) when you run the installer.

```
# Windows
./Get-OfflineLibrary.ps1 -Destination "E:\" -Region France
./Get-OfflineLibrary.ps1 -Destination "E:\" -Region "Germany,Austria"
./Get-OfflineLibrary.ps1 -Destination "E:\" -Region Europe        # a whole continent
./Get-OfflineLibrary.ps1 -Destination "E:\" -Region US_texas      # one sub-region

# macOS / Linux
./get-offline-library.sh -d /mnt/usb --region Japan
./get-offline-library.sh -d /mnt/usb --region world              # everything (huge!)
```

**Don't know the exact name?** List what's available (no download):
```
# Windows
./Get-OfflineLibrary.ps1 -ListRegions                 # all countries/regions
./Get-OfflineLibrary.ps1 -ListRegions -Filter US      # sub-regions of the US
# macOS / Linux
./get-offline-library.sh --list-regions               # all countries/regions
./get-offline-library.sh --list-regions France        # sub-regions of France
```

Notes:
- Accepts a **country** (`France`, `Kenya`, `Japan`), several (`"Germany,Austria"`), a
  **continent** (`Europe`, `Africa`, `Asia`, `North-America`, `South-America`,
  `Central-America`, `Australia-Oceania`), a **sub-region** (`US_texas`,
  `Germany_bayern`), or **`world`** for everything.
- **Common names and ISO codes also work** and are translated automatically — e.g. `UK`,
  `USA`, `GBR`, `DEU`, `FRA`, `JPN`, `UAE`, `Holland`, `Czech`. Anything unrecognized is
  tried as-is, so you can always use the exact OsmAnd name from `--list-regions`.
- Big countries are split into many files — picking the country name grabs them all.
- **Size varies a lot:** US ≈ 17 GB, a small country can be under 1 GB, a whole continent
  is tens of GB, and `world` is hundreds of GB. The installer prints the size before
  downloading and warns if it's very large.
- Everything else in this kit (the desktop viewer, phone apps, guides) works with **any**
  region's maps — only the selection changes.

---

## Option 1 — On a computer with the OsmAndMapCreator viewer

**On Windows and macOS this viewer needs internet:** it shows online map tiles from
`tile.osmand.net`, not the maps on the drive. With no internet the map area stays **blank**
([#15](https://github.com/elhajahmadj/offline-emergency-library/issues/15)). For offline use on a
computer, use the **browser maps** above (US) or an **Android phone** (Option 2; any region).
On **Linux x64** the bundled build has the offline renderer, so it may work offline, but that is
untested. Everything you need to launch it is bundled — **no separate install, no Java to set up.**

1. Open `OsmAnd\MapViewer-Desktop\`.
2. **Windows:** double-click **`VIEW-MAPS-ON-PC.bat`**.
   **macOS / Linux:** run **`./VIEW-MAPS-ON-PC.sh`** from a terminal in that folder.
   - The **first run** unzips the map files into `OsmAnd\obf\` (this can take several
     minutes and uses extra space — see note below), then opens the viewer.
   - Later runs skip straight to the viewer.
3. The **OsmAndMapCreator** window opens. Your maps are the `.obf` files in `OsmAnd\obf\`.
   Use the app's menus to open/browse a map, zoom, and search.

**Dependencies: fully handled.** This folder includes a **portable Java runtime** (`jre\`)
and the **OsmAndMapCreator** app (`app\`). Nothing else is required to launch it on a 64-bit PC.

> **Known limitation on Windows and macOS ([#15](https://github.com/elhajahmadj/offline-emergency-library/issues/15)):**
> the OsmAndMapCreator window opens, but it draws **downloaded online tiles**, not the `.obf`
> maps on the drive. The offline renderer it needs (`osmand-win-amd64.lib` on Windows,
> `osmand-mac-universal.lib` on macOS) is not in the bundled build, which only has the Linux one.
> With internet the map draws; with **no internet it is blank**. This was reproduced on Windows 11
> and macOS. **Offline on a computer, use the browser maps at the top of this guide** (US maps;
> re-run the installer with `-BrowserMaps` to add them). For non-US regions, use the maps on an
> **Android phone/tablet** (Option 2 below), which is fully tested.

> **Space note:** the maps download as compressed `.obf.zip` (~17 GB). Desktop viewing
> needs them **unzipped** to `.obf` (~30 GB), so the first run roughly doubles the map
> space. Make sure the drive has ~30 GB free before using desktop maps. (If space is
> tight, you can delete `OsmAnd\obf\` afterward; re-running the `.bat` recreates it.)

---

## Option 2 — On an Android phone/tablet

No app store or internet needed — the app is bundled.

1. Copy the OsmAnd APK from `Phone-Apps\` (e.g. `OsmAnd-XXXXXX.apk`) to your Android
   device. (See `Phone-Apps\USE-ON-PHONE` for the full phone setup, including Kiwix.)
2. On the device, tap the APK to install. You may need to allow **"Install unknown apps"**
   for your file manager/browser (Settings → Apps → special access).
3. Copy the **`.obf.zip`** map files (from `OsmAnd\`) into the OsmAnd maps folder on the
   device: typically `Android/data/net.osmand.plus/files/` — or in the OsmAnd app use
   **Menu → Configure map / Download maps → Import** and point it at the files.
4. Open OsmAnd. The maps work fully offline (navigation, search, routing).

**Dependency:** the **OsmAnd app** — bundled here as the **OsmAnd~ APK** (the free,
full-featured F-Droid build), so you can install it offline.

---

## Option 3 — On an iPhone/iPad ⚠️

Apple does **not** allow installing apps offline from a file. So:

1. **While you still have internet,** install **OsmAnd Maps** from the **App Store**
   (free). Do this now as part of preparing your kit.
2. Later, import the `.obf` map files into OsmAnd on iOS (via Files / iTunes file sharing),
   or download the regions inside the OsmAnd app while you still have a connection.

This is an Apple platform limitation — there's no offline sideloading like Android.

---

## Which should I use?

| You have… | Use | Dependency status |
|---|---|---|
| A Windows PC (US maps) | **Browser maps** (recommended) | ✅ renders reliably; opt-in `-BrowserMaps` (US only) |
| A computer, non-US maps | **Option 2** (Android phone/tablet) | ✅ bundled APK. The Option 1 desktop viewer is blank offline on Windows and macOS ([#15](https://github.com/elhajahmadj/offline-emergency-library/issues/15)); Linux untested |
| An Android phone/tablet | **Option 2** (bundled APK) | ✅ bundled APK |
| An iPhone/iPad | **Option 3** (App Store) | ⚠️ install the app while online |

---

## Notes

- The maps are standard **OsmAnd `.obf`** vector maps — detailed roads, towns, terrain,
  and search; routing works in the phone app.
- The desktop viewer (OsmAndMapCreator) is utilitarian. It works for finding places, roads,
  and coordinates with internet on Windows and macOS; offline on those, use browser maps or a phone.
- Keep a **paper topographic map and compass** as an ultimate backup - electronics fail.
  Print [Map and compass - navigation without a device](MAP-AND-COMPASS.html)
  and practice reading terrain, following bearings and finding direction without power.
