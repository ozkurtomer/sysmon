<div align="center">

<img src="assets/icon.png" width="104" alt="SysMon icon">

# SysMon

**Your Mac's vitals, as a game HUD — right in the menu bar.**
<br>
<sub>Mac'inin sağlığı, menü çubuğunda bir oyun arayüzü olarak.</sub>

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/demo-en-dark.gif">
  <img src="assets/demo-en-light.gif" width="400" alt="SysMon popover: CPU, RAM, disk and battery gauges with the top resource-hungry apps shown as enemies">
</picture>

<br><br>

[![Release](https://img.shields.io/github/v/release/ozkurtomer/sysmon?color=7ecdb8&label=release)](https://github.com/ozkurtomer/sysmon/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/ozkurtomer/sysmon/total?color=7ecdb8)](https://github.com/ozkurtomer/sysmon/releases)
[![Build](https://github.com/ozkurtomer/sysmon/actions/workflows/build.yml/badge.svg)](https://github.com/ozkurtomer/sysmon/actions/workflows/build.yml)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-2b303c?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-f05138?logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-a6aebe)](LICENSE)

**English** · [Türkçe](README.tr.md)

[**Download**](https://github.com/ozkurtomer/sysmon/releases/latest) · [Report a bug](https://github.com/ozkurtomer/sysmon/issues/new/choose) · [Ideas](https://github.com/ozkurtomer/sysmon/discussions)

</div>

---

## Why SysMon?

Activity Monitor is powerful, but it's a whole window of numbers. SysMon turns the same information into something you can read in half a second — a tiny HUD in your menu bar that tells you *how your Mac is doing* and *who's to blame* when it isn't.

- **Glanceable.** `CPU 23%  RAM 72%` lives in the menu bar and turns red when things get tight.
- **Playful, not noisy.** Segmented gauges, a status banner, and your heaviest apps as "enemies" — with a **BOSS** tag for the one hogging the machine.
- **Light on resources.** Native Swift/SwiftUI, no dependencies. Idle usage is around 0.4% CPU and ~45 MB.
- **Private.** Everything is computed locally. No network access, no analytics, no accounts.

## Features

| | |
| --- | --- |
| **Live menu bar readout** | CPU and RAM, refreshed every 2 seconds, turns red under pressure |
| **Game-style HUD** | Segmented gauges for CPU, RAM, Disk and Battery |
| **Status banner** | *All clear* → *Enemies nearby* → *Boss fight!* / *Low health!* |
| **Enemies list** | Top apps by CPU or RAM, with a BOSS badge for the worst offender |
| **Defeat button** | Politely ask a misbehaving app to quit (it will still ask to save your work) |
| **Level & XP** | Your Mac levels up with every day of uptime ("playtime") |
| **Follows your Mac** | Automatic light / dark appearance and your system language |
| **Languages** | English and Türkçe — switch any time from ⚙︎ → Language |
| **Launch at login** | One click from the ⚙︎ menu |

## How the game maps to your Mac

| In the game | On your Mac |
| --- | --- |
| ⚡ **CPU gauge** | Overall CPU usage |
| 🧠 **RAM gauge** | Active + wired + compressed memory vs. installed RAM |
| 💾 **Disk gauge** | Used space on the startup volume |
| 🔋 **Battery gauge** | Charge level (shown on laptops) |
| 👾 **Enemies** | The apps using the most CPU or memory right now |
| 👑 **BOSS** | An app using ≥ 30% CPU (or a huge share of RAM) |
| 🎮 **Level / playtime** | Days since last boot (Lv. 1 = first day) |
| ❤️ **Low health!** | RAM usage above 92% |

> macOS deliberately keeps RAM and disk fairly full, so gauges only turn orange above 80% and red above 92%.

## Install

### Option 1 — One command (recommended)

Open **Terminal** and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/ozkurtomer/sysmon/main/scripts/install.sh | bash
```

It downloads the latest release, installs SysMon into **Applications** and launches it — **no security warning**, because files fetched this way aren't quarantined by macOS. The script is [short and readable](scripts/install.sh).

### Option 2 — Download the DMG

1. Download **`SysMon.dmg`** from the [latest release](https://github.com/ozkurtomer/sysmon/releases/latest) and drag **SysMon** into **Applications**.
2. Open SysMon. If macOS says *"Apple could not verify SysMon is free of malware"*, click **Done** (not *Move to Trash*), then:
   - **macOS 15 Sequoia and later:** System Settings → **Privacy & Security** → scroll to *Security* → **Open Anyway** next to SysMon → confirm with your password.
   - **macOS 13–14:** right-click SysMon → **Open** → **Open**.
   - **Or in Terminal** (any version): `xattr -dr com.apple.quarantine /Applications/SysMon.app`

> **Why the warning?** SysMon is open source and ad-hoc signed, but not *notarized* — Apple only notarizes apps from paid Developer accounts ($99/year). The warning is about that missing paperwork, not about what the app does. You can read every line in [`Sources/`](Sources), or build it yourself below.

**Requirements:** macOS 13 Ventura or later · Apple Silicon or Intel.

## Build from source

You need the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/ozkurtomer/sysmon.git
cd sysmon
./scripts/build.sh          # universal .app + DMG in ./build
open build/SysMon.app
```

Regenerate the README animations from the real SwiftUI view with `./scripts/make-media.sh` (needs `pip install pillow`).

## How it works

| Metric | Source |
| --- | --- |
| CPU | `host_statistics` tick deltas between refreshes |
| RAM | `host_statistics64` — active + wired + compressor pages |
| Disk | `URLResourceValues` on `/` (important-usage capacity) |
| Battery | IOKit `IOPSCopyPowerSourcesInfo` |
| Top apps | `ps`, sorted by CPU / memory — fetched only while the panel is open |

The panel is a SwiftUI view hosted in an `NSPopover`, so light/dark mode and vibrancy come straight from macOS.

## Roadmap

Ideas that would make great contributions — pick one and open a PR:

- [ ] More languages (add a dictionary in [`Strings.swift`](Sources/Strings.swift) — it's ~25 lines)
- [ ] GPU and network gauges
- [ ] Temperature / fan readout (Apple Silicon sensors)
- [ ] Achievements & streaks ("Calm Seas: 1 hour under 10% CPU")
- [ ] Alternative HUD themes (retro pixel, minimal)
- [ ] Notarized builds & a Homebrew cask

Browse [`good first issue`](https://github.com/ozkurtomer/sysmon/labels/good%20first%20issue) for starter tasks.

## Contributing

Contributions of every size are welcome — code, translations, design, docs, bug reports. Start with [CONTRIBUTING.md](CONTRIBUTING.md); please also read the [Code of Conduct](CODE_OF_CONDUCT.md).

<a href="https://github.com/ozkurtomer/sysmon/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=ozkurtomer/sysmon" alt="Contributors">
</a>

## Support the project

If SysMon is useful to you, a ⭐ **star** helps other people find it — thank you!

[![Star History Chart](https://api.star-history.com/svg?repos=ozkurtomer/sysmon&type=Date)](https://star-history.com/#ozkurtomer/sysmon&Date)

## License

[MIT](LICENSE) © 2026 [Ömer Özkurt](https://github.com/ozkurtomer)
