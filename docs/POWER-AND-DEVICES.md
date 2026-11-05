# Power and devices: keep the library usable off-grid

**Start with reading, not AI.** Keep a charged phone or tablet with the essential
PDFs, HTML guides and local maps already copied onto it. Dim the screen, close
unused apps, and use airplane mode when you do not need communications. Keep a
paper map and printed essential instructions as the no-battery fallback.

This guide works offline. The source links at the end are for checking details
while you still have internet; none is needed to use the calculations below.

## 1. Budget energy for a day

**Watts (W) are power; watt-hours (Wh) are energy.** A device drawing 5 W for
4 hours uses 20 Wh. Add each task's energy to estimate a day [1]:

- Energy used: `Wh = average W x hours`.
- Battery energy: `Wh = (mAh / 1000) x rated battery V`.
- Runtime: `hours = usable Wh / average W`.

Use the battery's printed **Wh** rating when available. A 20,000 mAh bank rated
at a cell voltage of 3.7 V stores 74 Wh, **not** 100 Wh just because its USB output
is 5 V. If you assume 80% reaches your device after conversion, it delivers
about 59 Wh. That 80% is a planning assumption, not a guarantee; age, temperature,
cable losses and converter efficiency change it. Do not apply the loss twice
if the maker already specifies usable output energy.

**Example reading day (illustrative inputs, not measured device benchmarks):**

- Phone reading PDFs, HTML or Kiwix: assume 3 W for 4 hours = **12 Wh**.
- Laptop reading local maps/manuals: assume 15 W for 2 hours = **30 Wh**.
- Brief laptop AI use: assume 45 W for 20 minutes = **15 Wh**.
- Total delivered to devices: **57 Wh/day**. At the assumed 80% delivery,
  allow about **72 Wh of stored energy**. With a separate 25% reserve, plan for
  about **90 Wh/day**. Two days with no recharge need about **180 Wh**.

Replace these assumptions with a USB power meter, plug-in energy meter, or a
timed battery-use test on **your** setup. Include the screen, external drive,
fans, networking and converter losses at the measurement boundary. A charger's
65 W rating is its maximum output, not a measurement of what the laptop uses.

### Reading versus AI

Searching a local PDF or ZIM normally needs less sustained computation than
generating AI text. The screen and the device's idle load still use energy.
An 8B/7B model can keep the CPU/GPU busy; do not budget it as if it were reading.

Prefer the **3B model** for brief questions; close the chat/server afterward.
Use manuals directly for safety-critical decisions. Model size alone does not
predict Wh per answer: hardware, response length and time taken also matter.
Measure before depending on a runtime estimate.

For a smaller initial download, use **`-Lite` / `--lite`**, paired with a small
**`-Region` / `--region`** or **`-SkipMaps` / `--skip-maps`**. Lite keeps the 3B
model but omits the larger models and several big archives. It reduces download
and storage work, **not** the power draw automatically. Maps still default to
the whole US; lite does not remove files already present.

## 2. Choose a charging route

### Power bank or battery station

Compare **Wh capacity** and **output W** separately. Enough energy for a day does
not mean the output can run a laptop: the bank, port and cable must support the
device's required USB-C Power Delivery voltage/current profile. A USB-C connector
alone does not prove compatibility. Test charging while using the actual device.

Prefer a compatible regulated DC/USB output over converting battery DC to mains
AC and back again when practical. If an inverter is necessary, budget its idle
draw and losses too. Follow the battery maker's charging-temperature limits;
keep batteries dry and out of hot vehicles/direct sun. Stop using swollen,
damaged or overheating batteries. Do not improvise battery packs or wiring.

### Solar: collect energy into a battery, then use it

Use a panel with a compatible charge controller or regulated USB charger.
**Never connect an unregulated panel directly to a device or lithium battery.**
Keep the panel in sun but the battery shaded and within its temperature limits.
Check whether simultaneous charging and output is supported; do not assume it.

For a first estimate, multiply panel W by **peak-sun-hours** and an assumed
overall collection efficiency. Peak-sun-hours mean equivalent hours at full
rated irradiance, not the time between sunrise and sunset.

- Example: **30 W x 4 peak-sun-hours x 0.6 = 72 Wh/day** collected.
- Four hours and 60% are **example assumptions**, not a forecast for your area.
  Shade, clouds, winter, panel angle and charging losses can reduce output
  sharply; a storm day may provide almost nothing.
- That example would not replenish the 90 Wh/day reserve-inclusive budget above.
  Under those same assumptions, the arithmetic minimum is about **38 W** of
  panel; choose headroom and test rather than buying to that minimum.
- Check local seasonal solar resources before an outage (PVWatts is one planning
  tool [2]). It models PV systems, not your portable USB charger. Keep stored
  energy for days with no useful sun.

### Vehicle / 12 V

Use a vehicle-rated, fused USB/DC adapter within the socket and device ratings;
do not wire a computer straight to a starter battery. Check the vehicle manual:
some sockets turn off with the ignition, others can drain the starter battery.
Preserve enough charge to start the vehicle; there is no universal safe runtime.

If the engine must run, use it **outdoors, never in a garage or enclosed space,
even with the door open**. Keep exhaust clear, including snow, and away from
people and openings. Carbon monoxide can kill [4]. Fuel is finite; do not
depend on idling as your only charging plan.

### Hand-crank

Treat a crank as a short top-up for a light, radio or phone, not a laptop power
source. Ask what sustained **electrical output W** it actually delivers.
Even **5 W for 10 minutes** is only **0.83 Wh before losses**. That is arithmetic
for an assumed output, not a claim that a particular crank achieves it.

## 3. Pick the lowest-power setup that does the job

- **Phone/tablet:** often the practical first choice for reading, because screen,
  storage and battery are integrated. Download apps, import files and test
  airplane-mode use now. Copy only the regions/references you need; see the
  bundled `USE-ON-PHONE` guide.
- **E-reader:** useful for supported PDFs/ebooks with long periods of static
  reading. Test layout and transfer first. Do not assume it can run Kiwix, maps
  or AI. Keep a print copy of essential pages.
- **Laptop:** convenient for the complete library, but a gaming GPU, bright
  screen and background apps can dominate the budget. Use power-saving mode,
  an integrated GPU where available, and short reading sessions.
- **Raspberry Pi:** can be a low-power reading/server option, **not a ready-to-run
  appliance included with this kit**. Budget the board plus drive, display or
  client phone, cooling and networking. Set up the OS and compatible readers
  while online. The bundled Linux Kiwix AppImage is x64, not a Pi ARM build;
  use **`kiwix-serve` in a browser**, as below, rather than a desktop app. Test any AI engine and
  its RAM needs on your exact OS; do not assume desktop bundles work unchanged.

For scale, official Raspberry Pi documentation lists roughly **600 mA at 5.1 V**
for a typical active **bare Pi 4 board**: about **3 W before peripherals** [3].
This is neither a complete workstation budget nor an AI benchmark. A Pi 5 needs
a suitable **5 V / 5 A** supply for the higher USB peripheral power allowance;
ordinary USB-C banks may not offer that profile. Undervoltage can cause storage
corruption. Shut down cleanly before disconnecting the drive or power.

### Read ZIMs on Raspberry Pi / Linux ARM

While online, install **Kiwix tools for your Linux ARM OS/architecture**
(including `kiwix-serve`), mount the library drive, and locate its `.zim` files.
The tools are a separate prerequisite, not installed by this kit. Then serve
your local ZIMs and read them in the Pi's browser [5], for example:

```bash
kiwix-serve --address=127.0.0.1 --port=8080 \
  "/media/pi/LIBRARY/OfflineLibrary/Medical/WikiMed/"*.zim
```

Replace the example mount path with your actual folder containing ZIM files.
Open **`http://127.0.0.1:8080` on the Pi** and select a book. Leave the terminal
running; **Ctrl+C** stops the server. This works without internet once the
tools and ZIMs are present. Test it before the outage.

That address is **local to the Pi**: a phone cannot use its own `127.0.0.1` to
reach it. Serving a phone on a trusted local network requires deliberately
binding the server to the Pi's LAN address instead, and allowing that port in
the local firewall. Use the Pi's address in the phone browser; do not forward
the port on an internet router. Account for local network equipment's power.

A preconfigured Pi + library drive + battery + suitably sized panel can serve
light reading through a phone, without powering a laptop display. Count the
client phone and local Wi-Fi too; local networking does not require internet.
**Browser maps are proposed in PR #10, not shipped in the current main kit.**
If using that opt-in version, prepare maps/viewer assets and test the whole
setup offline first; do not assume it supports every region or Pi configuration.
The current bundled desktop Java map viewer is blank with no internet on Windows
and macOS (issue #15). A phone with tested offline maps is a simpler fallback.

## 4. Rehearse before relying on it

1. Charge everything and copy essential references to a second device.
2. Disconnect internet; open a PDF, a ZIM and your local map. Locate instructions
   without AI. Keep emergency communications available when you need them.
3. Run your expected reading/AI session and measure energy used. Test the exact
   bank, charging cable, panel and adapters together, including low battery.
4. Save enough stored energy for poor-weather days and communications. Print
   critical instructions and a local paper map. Recheck batteries periodically
   following the maker's storage guidance.

## Sources and limits

Checked 2026-11-03. This is original guidance under the repository's MIT license,
with references below, not copied equipment manuals or product endorsements.
The worked power/solar examples are **assumptions to replace with measurements**.

1. [US EIA: measuring electricity](https://www.eia.gov/energyexplained/electricity/measuring-electricity.php) - W, Wh and energy over time.
2. [PVWatts](https://pvwatts.nlr.gov/) - location/weather-dependent solar estimates and model limitations.
3. [Raspberry Pi official power documentation](https://github.com/raspberrypi/documentation/blob/master/documentation/asciidoc/computers/raspberry-pi/power-supplies.adoc) - board-only figures, power-supply profiles, USB budgets and undervoltage.
4. [US National Weather Service: winter safety during a storm](https://www.weather.gov/safety/winter-during) - vehicle exhaust, ventilation and carbon-monoxide precautions.
5. [Kiwix tools: kiwix-serve](https://kiwix-tools.readthedocs.io/en/latest/kiwix-serve.html) - local ZIM serving, browser access, listen address and port options.
